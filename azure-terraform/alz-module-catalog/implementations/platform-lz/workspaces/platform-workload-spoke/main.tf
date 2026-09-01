data "tfe_outputs" "management" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.management_workspace_name
}

data "tfe_outputs" "connectivity" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.connectivity_workspace_name
}

locals {
  enabled = try(var.workload_spoke.enabled, false)

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  connectivity_outputs = merge(
    try(data.tfe_outputs.connectivity[0].nonsensitive_values, {}),
    try(data.tfe_outputs.connectivity[0].values, {})
  )

  log_analytics_workspace_id = coalesce(var.log_analytics_workspace_id, try(local.management_outputs.log_analytics_workspace_id, null))

  hub_connection = try(var.workload_spoke.hub_connection, null) != null ? var.workload_spoke.hub_connection : (
    try(local.connectivity_outputs.hub_virtual_network_id, null) == null ? null : {
      hub_virtual_network_id  = local.connectivity_outputs.hub_virtual_network_id
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    }
  )

  generated_private_dns_zone_links = {
    for key in var.private_dns_zone_link_keys : key => {
      private_dns_zone_name = local.connectivity_outputs.private_dns_zone_names[key]
      resource_group_name   = local.connectivity_outputs.private_dns_zone_resource_group_names[key]
      registration_enabled  = false
    }
    if contains(keys(try(local.connectivity_outputs.private_dns_zone_names, {})), key)
  }

  private_dns_zone_links = length(try(var.workload_spoke.private_dns_zone_links, {})) > 0 ? var.workload_spoke.private_dns_zone_links : local.generated_private_dns_zone_links

  workload_key_vault = (
    try(var.workload_spoke.workload_key_vault.enabled, false) &&
    local.log_analytics_workspace_id != null &&
    try(var.workload_spoke.workload_key_vault.diagnostics.log_analytics_workspace_id, null) == null
    ) ? merge(var.workload_spoke.workload_key_vault, {
      diagnostics = merge(try(var.workload_spoke.workload_key_vault.diagnostics, {}), {
        log_analytics_workspace_id = local.log_analytics_workspace_id
      })
  }) : try(var.workload_spoke.workload_key_vault, { enabled = false })
}

module "workload_spoke" {
  source = "../../../../patterns/terraform-azurerm-compeer-workload-spoke"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  location                        = var.location
  environment                     = var.environment
  workload_tags                   = merge(var.workload_tags, try(var.workload_spoke.workload_tags, try(var.workload_spoke.platform_tags, {})))
  resource_group                  = try(var.workload_spoke.resource_group, null)
  spoke_vnet                      = try(var.workload_spoke.spoke_vnet, null)
  hub_connection                  = local.hub_connection
  private_dns_zone_links          = local.private_dns_zone_links
  workload_identity               = try(var.workload_spoke.workload_identity, { enabled = false })
  workload_key_vault              = local.workload_key_vault
  role_assignments                = try(var.workload_spoke.role_assignments, {})
  management_locks                = try(var.workload_spoke.management_locks, {})
  diagnostic_settings             = try(var.workload_spoke.diagnostic_settings, {})
  additional_scopes               = try(var.workload_spoke.additional_scopes, {})
  network_security_groups         = try(var.workload_spoke.network_security_groups, {})
  subnet_nsg_associations         = try(var.workload_spoke.subnet_nsg_associations, {})
  route_tables                    = try(var.workload_spoke.route_tables, {})
  subnet_route_table_associations = try(var.workload_spoke.subnet_route_table_associations, {})
  private_endpoints               = try(var.workload_spoke.private_endpoints, {})
}
