locals {
  enabled = try(var.network_peering.enabled, false)
}

module "network_peering" {
  source = "../../../../patterns/terraform-azurerm-compeer-network-peering"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  tenant_id                            = var.tenant_id
  hub_subscription_id                  = var.hub_subscription_id
  spoke_subscription_id                = var.spoke_subscription_id
  use_tfe_outputs                      = try(var.network_peering.use_tfe_outputs, true)
  tfe_organization                     = coalesce(try(var.network_peering.tfe_organization, null), "Compeer-Financial-Services")
  platform_connectivity_workspace_name = try(var.network_peering.platform_connectivity_workspace_name, "platform-connectivity")
  workload_spoke_workspace_name        = try(var.network_peering.workload_spoke_workspace_name, "workload-spoke")
  hub_resource_group_name              = try(var.network_peering.hub_resource_group_name, null)
  hub_virtual_network_name             = try(var.network_peering.hub_virtual_network_name, null)
  hub_virtual_network_id               = try(var.network_peering.hub_virtual_network_id, null)
  spoke_resource_group_name            = try(var.network_peering.spoke_resource_group_name, null)
  spoke_virtual_network_name           = try(var.network_peering.spoke_virtual_network_name, null)
  spoke_virtual_network_id             = try(var.network_peering.spoke_virtual_network_id, null)
  peering_name_prefix                  = try(var.network_peering.peering_name_prefix, "platform-lz")
  hub_to_spoke                         = try(var.network_peering.hub_to_spoke, {})
  spoke_to_hub                         = try(var.network_peering.spoke_to_hub, {})
  private_dns_zone_resource_group_name = try(var.network_peering.private_dns_zone_resource_group_name, null)
  private_dns_zones                    = try(var.network_peering.private_dns_zones, {})
  tags                                 = try(var.network_peering.tags, {})
}
