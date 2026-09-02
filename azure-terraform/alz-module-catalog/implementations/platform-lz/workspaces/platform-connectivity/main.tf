data "tfe_outputs" "management" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.management_workspace_name
}

locals {
  enabled = try(var.connectivity.enabled, false)

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  log_analytics_workspace_id = coalesce(var.log_analytics_workspace_id, try(local.management_outputs.log_analytics_workspace_id, null))

  bastion = merge(
    try(var.connectivity.bastion, { enabled = false }),
    (
      try(var.connectivity.bastion.enabled, false) &&
      local.log_analytics_workspace_id != null &&
      length(try(var.connectivity.bastion.diagnostic_settings, {})) == 0
      ) ? {
      diagnostic_settings = {
        law = {
          log_analytics_workspace_id = local.log_analytics_workspace_id
        }
      }
    } : {}
  )
}

module "connectivity" {
  source = "../../../../patterns/terraform-azurerm-compeer-platform-connectivity"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id = var.subscription_id
  location        = var.location
  environment     = var.environment
  platform_tags   = merge(var.platform_tags, try(var.connectivity.platform_tags, {}))
  # Default names come from the naming module (Appendix F); anything set in
  # tfvars overrides via merge().
  resource_group                  = merge({ name = local.std_names.resource_group }, try(var.connectivity.resource_group, {}))
  hub_vnet                        = merge({ name = local.std_names.hub_vnet }, try(var.connectivity.hub_vnet, null) == null ? {} : var.connectivity.hub_vnet)
  ddos_protection_plan            = try(var.connectivity.ddos_protection_plan, { enabled = false })
  palo_alto                       = try(var.connectivity.palo_alto, { enabled = false })
  dns_resolution                  = try(var.connectivity.dns_resolution, { enabled = false })
  private_dns_resolver            = try(var.connectivity.private_dns_resolver, { enabled = false })
  bastion                         = local.bastion
  network_security_groups         = try(var.connectivity.network_security_groups, {})
  subnet_nsg_associations         = try(var.connectivity.subnet_nsg_associations, {})
  route_tables                    = try(var.connectivity.route_tables, {})
  subnet_route_table_associations = try(var.connectivity.subnet_route_table_associations, {})
  public_ips                      = try(var.connectivity.public_ips, {})
  route_server_public_ips         = try(var.connectivity.route_server_public_ips, {})
  route_servers                   = try(var.connectivity.route_servers, {})
  load_balancers                  = try(var.connectivity.load_balancers, {})
  network_watchers                = try(var.connectivity.network_watchers, {})
  local_network_gateways          = try(var.connectivity.local_network_gateways, {})
  network_watcher_flow_logs       = try(var.connectivity.network_watcher_flow_logs, {})
  private_dns_zones               = try(var.connectivity.private_dns_zones, {})
  privatelink_zone_catalogue      = try(var.connectivity.privatelink_zone_catalogue, [])
  privatelink_zone_region         = try(var.connectivity.privatelink_zone_region, var.location)
  role_assignments                = try(var.connectivity.role_assignments, {})
  management_locks                = try(var.connectivity.management_locks, {})
  diagnostic_settings             = try(var.connectivity.diagnostic_settings, {})
  additional_scopes               = try(var.connectivity.additional_scopes, {})
}
