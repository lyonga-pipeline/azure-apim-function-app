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

resource "time_static" "deployment_created" {}

locals {
  enabled = try(var.directory_services.enabled, false)

  # This workspace owns the deployment-lifecycle boundary for every resource
  # it creates, so it - not the tags module - owns created_on's stability.
  # time_static computes its value once, on first apply, and stores it in
  # state; every later plan reuses the same value instead of recomputing it
  # (unlike timestamp(), which would re-diff this tag on every single plan).
  # This intentionally supersedes any created_on set in platform_tags below.
  deployment_created_on = formatdate("YYYY-MM-DD", time_static.deployment_created.rfc3339)

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  connectivity_outputs = merge(
    try(data.tfe_outputs.connectivity[0].nonsensitive_values, {}),
    try(data.tfe_outputs.connectivity[0].values, {})
  )

  log_analytics_workspace_id = try(coalesce(var.log_analytics_workspace_id, try(local.management_outputs.log_analytics_workspace_id, null)), null)

  # 23 Sep 2026 placement decision: the identity VNet is a peered spoke of the
  # hub, resolved the same way workload-spoke resolves its own hub_connection -
  # null (not an error) until connectivity has published hub_virtual_network_id,
  # so this workspace's first apply doesn't hard-depend on connectivity having
  # run first with this exact output already present.
  hub_connection = try(local.connectivity_outputs.hub_virtual_network_id, null) == null ? null : {
    hub_virtual_network_id = local.connectivity_outputs.hub_virtual_network_id
  }

  # subnet_id (legacy: an explicit/hub subnet) always wins when a caller sets
  # it; otherwise subnet_key is resolved against this workspace's own
  # identity_vnet INSIDE the pattern - not here, since the VNet is created by
  # the same module call these domain_controllers are passed into.
  domain_controllers = {
    for key, controller in try(var.directory_services.domain_controllers, {}) : key => merge({
      name     = local.domain_controller_names[key]
      nic_name = module.naming.network_interface_names[key]
      }, controller, {
      diagnostics = (
        coalesce(try(controller.diagnostics.enabled, null), false) &&
        local.log_analytics_workspace_id != null &&
        try(controller.diagnostics.log_analytics_workspace_id, null) == null
        ) ? merge(try(controller.diagnostics, {}), {
          log_analytics_workspace_id = local.log_analytics_workspace_id
      }) : try(controller.diagnostics, {})
    })
  }

  identity_vnet = try(var.directory_services.identity_vnet, null) == null ? null : merge(
    { name = local.std_names.identity_vnet },
    var.directory_services.identity_vnet
  )

  recovery_services_vaults = {
    for key, vault in try(var.directory_services.recovery_services_vaults, {}) : key => merge(
      { name = local.std_names.recovery_services_vault[key] },
      vault
    )
  }

  network_security_groups = {
    for key, nsg in try(var.directory_services.network_security_groups, {}) : key => merge(
      { name = local.std_names.nsg[key] },
      nsg
    )
  }

  route_tables = {
    for key, rt in try(var.directory_services.route_tables, {}) : key => merge(
      { name = local.std_names.route_table[key] },
      rt
    )
  }
}

module "directory_services" {
  source = "../../../../patterns/terraform-azurerm-compeer-directory-services"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id                 = var.subscription_id
  location                        = var.location
  environment                     = var.environment
  platform_tags                   = merge(var.platform_tags, try(var.directory_services.platform_tags, {}), { created_on = local.deployment_created_on })
  resource_group                  = merge({ name = local.std_names.resource_group }, try(var.directory_services.resource_group, {}))
  identity_vnet                   = local.identity_vnet
  hub_connection                  = local.hub_connection
  network_security_groups         = local.network_security_groups
  route_tables                    = local.route_tables
  subnet_nsg_associations         = try(var.directory_services.subnet_nsg_associations, {})
  subnet_route_table_associations = try(var.directory_services.subnet_route_table_associations, {})
  recovery_services_vaults        = local.recovery_services_vaults
  domain_controllers              = local.domain_controllers
  admin_passwords                 = var.admin_passwords
  domain_join_passwords           = var.domain_join_passwords
  dc_backup                       = try(var.directory_services.dc_backup, null)
  role_assignments                = try(var.directory_services.role_assignments, {})
  management_locks                = try(var.directory_services.management_locks, {})
  additional_scopes               = try(var.directory_services.additional_scopes, {})
  operational_contracts           = try(var.directory_services.operational_contracts, {})
}
