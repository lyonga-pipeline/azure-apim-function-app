# =============================================================================
# Naming standard (design-doc Appendix F). The naming module is the single
# versioned implementation of the names; this root feeds them into the
# management pattern (see the merge() calls in main.tf). A name set explicitly
# in terraform.tfvars still wins - use that only for a grandfathered resource.
# =============================================================================

module "naming" {
  source = "../../../../modules/terraform-azurerm-compeer-naming"

  region      = var.location
  environment = var.environment
  purpose     = "management"
}

# per-key: appcode / purpose token comes from the map key
module "naming_kv" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.management.platform_key_vaults, {})
  region      = var.location
  environment = var.environment
  appcode     = each.key
}

module "naming_sa" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.management.platform_storage_accounts, {})
  region      = var.location
  environment = var.environment
  purpose     = each.key
}

locals {
  std_names = {
    resource_group          = module.naming.resource_group          # platform-<region>-<env>-management-rg
    log_analytics_workspace = module.naming.log_analytics_workspace # <region>-<env>-loganalytics-workspace
    action_group            = module.naming.action_group            # platform-<region>-<env>-ag
    monitor_workspace       = module.naming.monitor_workspace       # platform-<region>-<env>-monitor
    recovery_services_vault = module.naming.recovery_services_vault # platform-<region>-<env>-rsv
  }

  # keyed collections - module name is the default, tfvars `name` overrides
  mgmt_key_vaults = {
    for k, v in try(var.management.platform_key_vaults, {}) : k => merge({ name = module.naming_kv[k].key_vault }, v)
  }
  mgmt_storage_accounts = {
    for k, v in try(var.management.platform_storage_accounts, {}) : k => merge({ name = module.naming_sa[k].storage_account }, v)
  }
  mgmt_recovery_vaults = {
    for k, v in try(var.management.recovery_services_vaults, {}) : k => merge({ name = local.std_names.recovery_services_vault }, v)
  }

  # diagnostic settings - derived from the resource they observe
  mgmt_storage_diagnostics = {
    for k, v in try(var.management.platform_storage_diagnostics, {}) : k => merge({ name = "diag-${local.mgmt_storage_accounts[k].name}-law" }, v)
  }
  mgmt_key_vault_diagnostics = {
    for k, v in try(var.management.platform_key_vault_diagnostics, {}) : k => merge({ name = "diag-${local.mgmt_key_vaults[k].name}-law" }, v)
  }
  mgmt_recovery_vault_diagnostics = {
    for k, v in try(var.management.recovery_services_vault_diagnostics, {}) : k => merge({ name = "diag-${local.mgmt_recovery_vaults[k].name}-law" }, v)
  }
}
