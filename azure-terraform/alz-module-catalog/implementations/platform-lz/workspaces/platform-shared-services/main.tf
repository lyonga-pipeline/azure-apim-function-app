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
  enabled = try(var.shared_services.enabled, false)

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  connectivity_outputs = merge(
    try(data.tfe_outputs.connectivity[0].nonsensitive_values, {}),
    try(data.tfe_outputs.connectivity[0].values, {})
  )

  log_analytics_workspace_id = coalesce(var.log_analytics_workspace_id, try(local.management_outputs.log_analytics_workspace_id, null))

  hub_connection = try(var.shared_services.hub_connection, null) != null ? var.shared_services.hub_connection : (
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

  private_dns_zone_links = length(try(var.shared_services.private_dns_zone_links, {})) > 0 ? var.shared_services.private_dns_zone_links : local.generated_private_dns_zone_links

  platform_key_vault = (
    try(var.shared_services.platform_key_vault.enabled, false) &&
    local.log_analytics_workspace_id != null &&
    try(var.shared_services.platform_key_vault.diagnostics.log_analytics_workspace_id, null) == null
    ) ? merge(var.shared_services.platform_key_vault, {
      diagnostics = merge(try(var.shared_services.platform_key_vault.diagnostics, {}), {
        log_analytics_workspace_id = local.log_analytics_workspace_id
      })
  }) : try(var.shared_services.platform_key_vault, { enabled = false })
}

module "shared_services" {
  source = "../../../../patterns/terraform-azurerm-compeer-shared-services"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  location                        = var.location
  environment                     = var.environment
  platform_tags                   = merge(var.platform_tags, try(var.shared_services.platform_tags, {}))
  resource_group                  = merge({ name = local.std_names.resource_group }, try(var.shared_services.resource_group, {}))
  spoke_vnet                      = merge({ name = local.std_names.shared_vnet }, try(var.shared_services.spoke_vnet, null) == null ? {} : var.shared_services.spoke_vnet)
  hub_connection                  = local.hub_connection
  private_dns_zone_links          = local.private_dns_zone_links
  platform_identity               = try(var.shared_services.platform_identity, { enabled = false })
  platform_key_vault              = local.platform_key_vault
  role_assignments                = try(var.shared_services.role_assignments, {})
  management_locks                = try(var.shared_services.management_locks, {})
  diagnostic_settings             = try(var.shared_services.diagnostic_settings, {})
  additional_scopes               = try(var.shared_services.additional_scopes, {})
  network_security_groups         = local.std_maps.network_security_groups
  subnet_nsg_associations         = try(var.shared_services.subnet_nsg_associations, {})
  route_tables                    = local.std_maps.route_tables
  subnet_route_table_associations = try(var.shared_services.subnet_route_table_associations, {})
  private_endpoints               = local.std_maps.private_endpoints
}
