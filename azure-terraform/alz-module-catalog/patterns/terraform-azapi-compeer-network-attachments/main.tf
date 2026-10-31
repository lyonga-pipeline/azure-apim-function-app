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
  resource_id            = var.hub.virtual_network_id
  response_export_values = ["properties.addressSpace.addressPrefixes"]
}

data "azapi_resource" "spoke" {
  for_each               = var.attachments
  type                   = "Microsoft.Network/virtualNetworks@2024-05-01"
  resource_id            = each.value.spoke_virtual_network_id
  response_export_values = ["properties.addressSpace.addressPrefixes"]
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
  parent_id = var.hub.virtual_network_id
  name      = local.peering_names[each.key].hub_to_spoke
  body = { properties = {
    remoteVirtualNetwork      = { id = each.value.spoke_virtual_network_id }
    allowVirtualNetworkAccess = true
    allowForwardedTraffic     = each.value.allow_forwarded_traffic
    allowGatewayTransit       = each.value.gateway_transit
    useRemoteGateways         = false
  } }
  # Provider-process mutex, NOT an Azure management lock or a cross-workspace gate.
  locks                  = [lower(var.hub.virtual_network_id)]
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
  parent_id = each.value.spoke_virtual_network_id
  name      = local.peering_names[each.key].spoke_to_hub
  body = { properties = {
    remoteVirtualNetwork      = { id = var.hub.virtual_network_id }
    allowVirtualNetworkAccess = true
    allowForwardedTraffic     = each.value.allow_forwarded_traffic
    allowGatewayTransit       = false
    useRemoteGateways         = each.value.gateway_transit
  } }
  locks                  = [lower(var.hub.virtual_network_id)]
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
