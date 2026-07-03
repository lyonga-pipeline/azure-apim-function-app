data "tfe_outputs" "platform_connectivity" {
  count        = var.use_tfe_outputs ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.platform_connectivity_workspace_name
}

data "tfe_outputs" "workload_spoke" {
  count        = var.use_tfe_outputs ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.workload_spoke_workspace_name
}

locals {
  platform_outputs = merge(
    try(data.tfe_outputs.platform_connectivity[0].nonsensitive_values, {}),
    try(data.tfe_outputs.platform_connectivity[0].values, {})
  )
  spoke_outputs = merge(
    try(data.tfe_outputs.workload_spoke[0].nonsensitive_values, {}),
    try(data.tfe_outputs.workload_spoke[0].values, {})
  )

  hub_resource_group_name_candidates  = compact([var.hub_resource_group_name, try(local.platform_outputs.hub_resource_group_name, ""), try(local.platform_outputs.resource_group_name, "")])
  hub_virtual_network_name_candidates = compact([var.hub_virtual_network_name, try(local.platform_outputs.hub_virtual_network_name, "")])
  hub_virtual_network_id_candidates   = compact([var.hub_virtual_network_id, try(local.platform_outputs.hub_virtual_network_id, "")])

  spoke_resource_group_name_candidates  = compact([var.spoke_resource_group_name, try(local.spoke_outputs.spoke_resource_group_name, ""), try(local.spoke_outputs.resource_group_name, "")])
  spoke_virtual_network_name_candidates = compact([var.spoke_virtual_network_name, try(local.spoke_outputs.spoke_virtual_network_name, "")])
  spoke_virtual_network_id_candidates   = compact([var.spoke_virtual_network_id, try(local.spoke_outputs.spoke_virtual_network_id, "")])

  private_dns_zone_resource_group_name_candidates = compact([var.private_dns_zone_resource_group_name, try(local.platform_outputs.resource_group_name, ""), try(local.platform_outputs.hub_resource_group_name, "")])

  hub_resource_group_name  = try(local.hub_resource_group_name_candidates[0], null)
  hub_virtual_network_name = try(local.hub_virtual_network_name_candidates[0], null)
  hub_virtual_network_id   = try(local.hub_virtual_network_id_candidates[0], null)

  spoke_resource_group_name  = try(local.spoke_resource_group_name_candidates[0], null)
  spoke_virtual_network_name = try(local.spoke_virtual_network_name_candidates[0], null)
  spoke_virtual_network_id   = try(local.spoke_virtual_network_id_candidates[0], null)

  private_dns_zone_resource_group_name = try(local.private_dns_zone_resource_group_name_candidates[0], null)

  resolved_required_values = {
    hub_resource_group_name              = local.hub_resource_group_name
    hub_virtual_network_name             = local.hub_virtual_network_name
    hub_virtual_network_id               = local.hub_virtual_network_id
    spoke_resource_group_name            = local.spoke_resource_group_name
    spoke_virtual_network_name           = local.spoke_virtual_network_name
    spoke_virtual_network_id             = local.spoke_virtual_network_id
    private_dns_zone_resource_group_name = local.private_dns_zone_resource_group_name
  }

  private_dns_zone_links = {
    for key, zone in var.private_dns_zones : key => {
      name                  = coalesce(try(zone.link_name, null), "lnk-${key}-${var.peering_name_prefix}-spoke")
      resource_group_name   = try([for value in [try(zone.resource_group_name, null), local.private_dns_zone_resource_group_name] : value if value != null && value != ""][0], null)
      private_dns_zone_name = zone.name
      virtual_network_id    = local.spoke_virtual_network_id
      registration_enabled  = try(zone.registration_enabled, false)
      tags                  = var.tags
    }
    if try(zone.link_to_spoke_enabled, true)
  }
}

resource "terraform_data" "resolved_input_validation" {
  input = local.resolved_required_values

  lifecycle {
    precondition {
      condition     = alltrue([for value in values(local.resolved_required_values) : value != null && value != ""])
      error_message = "network-peering could not resolve all hub/spoke inputs. Confirm TFE_TOKEN can read outputs from '${var.platform_connectivity_workspace_name}' and '${var.workload_spoke_workspace_name}', those workspaces have successful applies after outputs were added, or set use_tfe_outputs=false and provide the values manually."
    }
  }
}

module "hub_to_spoke_peering" {
  source = "../../../modules/vnet-peering"

  providers = {
    azurerm = azurerm.hub
  }

  name                         = "peer-${var.peering_name_prefix}-hub-to-spoke"
  resource_group_name          = local.hub_resource_group_name
  virtual_network_name         = local.hub_virtual_network_name
  remote_virtual_network_id    = local.spoke_virtual_network_id
  allow_virtual_network_access = var.hub_to_spoke.allow_virtual_network_access
  allow_forwarded_traffic      = var.hub_to_spoke.allow_forwarded_traffic
  allow_gateway_transit        = var.hub_to_spoke.allow_gateway_transit
  use_remote_gateways          = var.hub_to_spoke.use_remote_gateways

  depends_on = [terraform_data.resolved_input_validation]
}

module "spoke_to_hub_peering" {
  source = "../../../modules/vnet-peering"

  providers = {
    azurerm = azurerm.spoke
  }

  name                         = "peer-${var.peering_name_prefix}-spoke-to-hub"
  resource_group_name          = local.spoke_resource_group_name
  virtual_network_name         = local.spoke_virtual_network_name
  remote_virtual_network_id    = local.hub_virtual_network_id
  allow_virtual_network_access = var.spoke_to_hub.allow_virtual_network_access
  allow_forwarded_traffic      = var.spoke_to_hub.allow_forwarded_traffic
  allow_gateway_transit        = var.spoke_to_hub.allow_gateway_transit
  use_remote_gateways          = var.spoke_to_hub.use_remote_gateways

  depends_on = [terraform_data.resolved_input_validation]
}

module "private_dns_spoke_links" {
  source = "../../../modules/private-dns-vnet-link"

  providers = {
    azurerm = azurerm.hub
  }

  links = local.private_dns_zone_links
  tags  = var.tags

  depends_on = [
    module.hub_to_spoke_peering,
    module.spoke_to_hub_peering,
  ]
}
