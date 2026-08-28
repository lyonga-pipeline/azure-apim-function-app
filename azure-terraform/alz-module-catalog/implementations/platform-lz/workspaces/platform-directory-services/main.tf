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
  enabled = try(var.directory_services.enabled, false)

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  connectivity_outputs = merge(
    try(data.tfe_outputs.connectivity[0].nonsensitive_values, {}),
    try(data.tfe_outputs.connectivity[0].values, {})
  )

  log_analytics_workspace_id = coalesce(var.log_analytics_workspace_id, try(local.management_outputs.log_analytics_workspace_id, null))

  domain_controllers = {
    for key, controller in try(var.directory_services.domain_controllers, {}) : key => merge(controller, {
      subnet_id = coalesce(
        try(controller.subnet_id, null),
        try(local.connectivity_outputs.subnet_ids[controller.subnet_key], null),
        try(local.connectivity_outputs.subnet_ids["domain_controllers"], null)
      )
      diagnostics = (
        coalesce(try(controller.diagnostics.enabled, null), false) &&
        local.log_analytics_workspace_id != null &&
        try(controller.diagnostics.log_analytics_workspace_id, null) == null
        ) ? merge(try(controller.diagnostics, {}), {
          log_analytics_workspace_id = local.log_analytics_workspace_id
      }) : try(controller.diagnostics, {})
    })
  }
}

module "directory_services" {
  source = "../../../../patterns/terraform-azurerm-compeer-directory-services"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id       = var.subscription_id
  location              = var.location
  environment           = var.environment
  platform_tags         = merge(var.platform_tags, try(var.directory_services.platform_tags, {}))
  resource_group        = try(var.directory_services.resource_group, null)
  domain_controllers    = local.domain_controllers
  admin_passwords       = var.admin_passwords
  domain_join_passwords = var.domain_join_passwords
  role_assignments      = try(var.directory_services.role_assignments, {})
  management_locks      = try(var.directory_services.management_locks, {})
  additional_scopes     = try(var.directory_services.additional_scopes, {})
  operational_contracts = try(var.directory_services.operational_contracts, {})
}
