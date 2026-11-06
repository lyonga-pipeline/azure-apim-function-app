# PHASE2 NEW: environment/hub batch composition. Existing AzureRM single-pair APIs remain unchanged.
data "tfe_outputs" "hub" {
  count        = local.active ? 1 : 0
  organization = var.hub.organization
  workspace    = var.hub.workspace
}

data "tfe_outputs" "spoke" {
  for_each     = var.attachments
  organization = each.value.producer.organization
  workspace    = each.value.producer.workspace
}

data "azapi_client_config" "current" {
  count = local.active ? 1 : 0
}

# Read parents only; never create, import or update a VNet from attachment state.
data "azapi_resource" "hub" {
  count                  = local.active ? 1 : 0
  type                   = "Microsoft.Network/virtualNetworks@2024-05-01"
  resource_id            = local.hub_virtual_network_id
  response_export_values = ["properties.addressSpace.addressPrefixes"]
  lifecycle {
    precondition {
      condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", local.hub_virtual_network_id))
      error_message = "The approved hub workspace must publish a valid hub_virtual_network_id, or supply a matching explicit hub.virtual_network_id pin."
    }
  }
}

data "azapi_resource" "spoke" {
  for_each               = var.attachments
  type                   = "Microsoft.Network/virtualNetworks@2024-05-01"
  resource_id            = local.spoke_virtual_network_ids[each.key]
  response_export_values = ["properties.addressSpace.addressPrefixes"]
  lifecycle {
    precondition {
      condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", local.spoke_virtual_network_ids[each.key]))
      error_message = "Attachment ${each.key}: the approved producer must publish a valid spoke_virtual_network_id, directly or in its attachment contract. An explicit ID pin must also match that contract."
    }
  }
}

# PHASE 2: optional read-only adapter for existing v2 producers without context outputs.
# Stable attachment keys keep planning independent of computed subscription IDs.
data "azapi_resource" "spoke_subscription" {
  for_each               = local.azure_context_attachments
  type                   = "Microsoft.Resources/subscriptions@2022-12-01"
  resource_id            = try(regex("(?i)^/subscriptions/[0-9a-f-]{36}", local.spoke_virtual_network_ids[each.key]), null)
  response_export_values = ["tenantId", "subscriptionId"]
  lifecycle {
    precondition {
      condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", local.spoke_virtual_network_ids[each.key]))
      error_message = "Attachment ${each.key}: a valid producer VNet ID is required before reading its subscription metadata."
    }
  }
}

data "azapi_resource" "hub_subscription" {
  count                  = length(local.azure_context_attachments) > 0 ? 1 : 0
  type                   = "Microsoft.Resources/subscriptions@2022-12-01"
  resource_id            = try(regex("(?i)^/subscriptions/[0-9a-f-]{36}", local.hub_virtual_network_id), null)
  response_export_values = ["tenantId", "subscriptionId"]
  lifecycle {
    precondition {
      condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", local.hub_virtual_network_id))
      error_message = "A valid hub producer VNet ID is required before reading its subscription metadata."
    }
  }
}

module "naming" {
  source                 = "./modules/attachment-names"
  for_each               = var.attachments
  private_dns_link_vnets = [local.spoke_names[each.key]]
  vnet_peerings = each.value.peering_names == null ? {
    hub   = { local_vnet = local.hub_name, remote_vnet = local.spoke_names[each.key] }
    spoke = { local_vnet = local.spoke_names[each.key], remote_vnet = local.hub_name }
  } : {}
}

resource "azapi_resource" "hub_to_spoke" {
  for_each  = var.attachments
  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01"
  parent_id = local.hub_virtual_network_id
  name      = local.peering_names[each.key].hub_to_spoke
  body = { properties = {
    remoteVirtualNetwork      = { id = local.spoke_virtual_network_ids[each.key] }
    allowVirtualNetworkAccess = true
    allowForwardedTraffic     = each.value.allow_forwarded_traffic
    allowGatewayTransit       = each.value.gateway_transit
    useRemoteGateways         = false
  } }
  # Provider-process mutex, NOT an Azure management lock or a cross-workspace gate.
  locks                  = local.hub_virtual_network_id == null ? [] : [lower(local.hub_virtual_network_id)]
  response_export_values = ["properties.peeringState", "properties.provisioningState"]
  depends_on             = [terraform_data.inventory_contract, terraform_data.producer_contract, terraform_data.ipam_contract]
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "azapi_resource" "spoke_to_hub" {
  for_each  = var.attachments
  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01"
  parent_id = local.spoke_virtual_network_ids[each.key]
  name      = local.peering_names[each.key].spoke_to_hub
  body = { properties = {
    remoteVirtualNetwork      = { id = local.hub_virtual_network_id }
    allowVirtualNetworkAccess = true
    allowForwardedTraffic     = each.value.allow_forwarded_traffic
    allowGatewayTransit       = false
    useRemoteGateways         = each.value.gateway_transit
  } }
  locks                  = local.hub_virtual_network_id == null ? [] : [lower(local.hub_virtual_network_id)]
  response_export_values = ["properties.peeringState", "properties.provisioningState"]
  # All hub permissions must exist before any spoke uses a remote gateway.
  depends_on = [azapi_resource.hub_to_spoke]
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "azapi_resource" "dns_link" {
  for_each  = local.dns_links
  type      = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01"
  parent_id = each.value.zone_id
  name      = each.value.name
  location  = "global"
  tags      = each.value.tags
  body = { properties = {
    registrationEnabled = false
    virtualNetwork      = { id = each.value.virtual_network_id }
  } }
  locks                  = [lower(each.value.zone_id)]
  response_export_values = ["properties.provisioningState"]
  depends_on             = [azapi_resource.spoke_to_hub]
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
