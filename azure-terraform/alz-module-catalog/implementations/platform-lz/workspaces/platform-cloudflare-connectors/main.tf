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
  enabled = try(var.cloudflare_connectors.enabled, false)

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  connectivity_outputs = merge(
    try(data.tfe_outputs.connectivity[0].nonsensitive_values, {}),
    try(data.tfe_outputs.connectivity[0].values, {})
  )

  log_analytics_workspace_id = coalesce(var.log_analytics_workspace_id, try(local.management_outputs.log_analytics_workspace_id, null))

  connectors = {
    for key, connector in try(var.cloudflare_connectors.connectors, {}) : key => merge(connector, {
      subnet_id = coalesce(
        try(connector.subnet_id, null),
        try(local.connectivity_outputs.subnet_ids[connector.subnet_key], null),
        try(local.connectivity_outputs.subnet_ids["cloudflare_connectors"], null)
      )
      diagnostics = (
        coalesce(try(connector.diagnostics.enabled, null), false) &&
        local.log_analytics_workspace_id != null &&
        try(connector.diagnostics.log_analytics_workspace_id, null) == null
        ) ? merge(try(connector.diagnostics, {}), {
          log_analytics_workspace_id = local.log_analytics_workspace_id
      }) : try(connector.diagnostics, {})
    })
  }
}

module "cloudflare_connectors" {
  source = "../../../../patterns/terraform-azurerm-compeer-cloudflare-connectors"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id              = var.subscription_id
  location                     = var.location
  environment                  = var.environment
  platform_tags                = merge(var.platform_tags, try(var.cloudflare_connectors.platform_tags, {}))
  resource_group               = try(var.cloudflare_connectors.resource_group, null)
  connectors                   = local.connectors
  admin_passwords              = var.admin_passwords
  custom_data_by_key           = var.custom_data_by_key
  extension_protected_settings = var.extension_protected_settings
  role_assignments             = try(var.cloudflare_connectors.role_assignments, {})
  management_locks             = try(var.cloudflare_connectors.management_locks, {})
  additional_scopes            = try(var.cloudflare_connectors.additional_scopes, {})
  operational_contracts        = try(var.cloudflare_connectors.operational_contracts, {})
}
