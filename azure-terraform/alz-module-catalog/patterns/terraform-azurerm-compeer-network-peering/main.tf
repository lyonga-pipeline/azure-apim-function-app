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
  platform_outputs = try(data.tfe_outputs.platform_connectivity[0].nonsensitive_values, {})
  spoke_outputs    = try(data.tfe_outputs.workload_spoke[0].nonsensitive_values, {})

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
    hub_resource_group_name    = local.hub_resource_group_name
    hub_virtual_network_name   = local.hub_virtual_network_name
    hub_virtual_network_id     = local.hub_virtual_network_id
    spoke_resource_group_name  = local.spoke_resource_group_name
    spoke_virtual_network_name = local.spoke_virtual_network_name
    spoke_virtual_network_id   = local.spoke_virtual_network_id
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
      condition = alltrue([for value in values(local.resolved_required_values) : value != null && value != ""]) && alltrue([
        for link in values(local.private_dns_zone_links) : link.resource_group_name != null && link.resource_group_name != ""
      ])
      error_message = "network-peering could not resolve all hub/spoke inputs. Confirm TFE_TOKEN can read outputs from '${var.platform_connectivity_workspace_name}' and '${var.workload_spoke_workspace_name}', those workspaces have successful applies after outputs were added, or set use_tfe_outputs=false and provide the values manually."
    }
    precondition {
      condition = (
        can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", local.hub_virtual_network_id)) &&
        can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", local.spoke_virtual_network_id)) &&
        try(lower(local.hub_virtual_network_id) != lower(local.spoke_virtual_network_id), false) &&
        try(lower(split("/", local.hub_virtual_network_id)[2]) == lower(var.hub_subscription_id), false) &&
        try(lower(split("/", local.spoke_virtual_network_id)[2]) == lower(var.spoke_subscription_id), false) &&
        try(lower(split("/", local.hub_virtual_network_id)[4]) == lower(local.hub_resource_group_name), false) &&
        try(lower(split("/", local.hub_virtual_network_id)[8]) == lower(local.hub_virtual_network_name), false) &&
        try(lower(split("/", local.spoke_virtual_network_id)[4]) == lower(local.spoke_resource_group_name), false) &&
        try(lower(split("/", local.spoke_virtual_network_id)[8]) == lower(local.spoke_virtual_network_name), false)
      )
      error_message = "Peering requires two distinct full VNet IDs matching the explicitly resolved subscription, resource-group and VNet names."
    }
  }
}

module "attachment" {
  source                      = "../terraform-azurerm-compeer-hub-spoke-peering"
  providers                   = { azurerm.hub = azurerm.hub, azurerm.spoke = azurerm.spoke, azurerm.dns = azurerm.dns }
  hub_virtual_network_id      = local.hub_virtual_network_id
  spoke_virtual_network_id    = local.spoke_virtual_network_id
  hub_subscription_id         = var.hub_subscription_id
  spoke_subscription_id       = var.spoke_subscription_id
  private_dns_subscription_id = var.private_dns_subscription_id
  tenant_id                   = var.tenant_id
  peering_names               = var.peering_names
  peering_name_prefix         = var.peering_name_prefix
  hub_to_spoke                = var.hub_to_spoke
  spoke_to_hub                = var.spoke_to_hub
  private_dns_zones = { for key, link in local.private_dns_zone_links : key => {
    name      = link.private_dns_zone_name, resource_group_name = link.resource_group_name,
    link_name = link.name, registration_enabled = link.registration_enabled
  } }
  tags       = var.tags
  depends_on = [terraform_data.resolved_input_validation]
}
