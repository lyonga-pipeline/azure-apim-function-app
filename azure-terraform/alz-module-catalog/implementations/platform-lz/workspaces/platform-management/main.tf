locals {
  enabled = try(var.management.enabled, false)
}

module "management" {
  source = "../../../../patterns/terraform-azurerm-compeer-platform-management"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id                       = var.subscription_id
  location                              = var.location
  environment                           = var.environment
  platform_tags                         = merge(var.platform_tags, try(var.management.platform_tags, {}))
  resource_group                        = merge({ name = local.std_names.resource_group }, try(var.management.resource_group, {}))
  log_analytics                         = try(var.management.log_analytics, null)
  action_group                          = try(var.management.action_group, null)
  platform_storage_accounts             = try(var.management.platform_storage_accounts, {})
  platform_storage_diagnostics          = try(var.management.platform_storage_diagnostics, {})
  platform_storage_private_endpoints    = try(var.management.platform_storage_private_endpoints, {})
  platform_key_vaults                   = try(var.management.platform_key_vaults, {})
  platform_key_vault_diagnostics        = try(var.management.platform_key_vault_diagnostics, {})
  platform_key_vault_private_endpoints  = try(var.management.platform_key_vault_private_endpoints, {})
  recovery_services_vaults              = try(var.management.recovery_services_vaults, {})
  recovery_services_vault_diagnostics   = try(var.management.recovery_services_vault_diagnostics, {})
  data_collection_endpoints             = try(var.management.data_collection_endpoints, {})
  data_collection_rules                 = try(var.management.data_collection_rules, {})
  data_collection_rule_associations     = try(var.management.data_collection_rule_associations, {})
  sentinel                              = try(var.management.sentinel, { enabled = false })
  resource_provider_registrations       = try(var.management.resource_provider_registrations, {})
  role_assignments                      = try(var.management.role_assignments, {})
  subscription_activity_log_diagnostics = try(var.management.subscription_activity_log_diagnostics, null)
  entra_diagnostic_settings             = try(var.management.entra_diagnostic_settings, null)
  subscription_budgets                  = try(var.management.subscription_budgets, {})
  management_locks                      = try(var.management.management_locks, {})
  additional_lock_scopes                = try(var.management.additional_lock_scopes, {})
  defender_plans                        = try(var.management.defender_plans, {})
  security_contact                      = try(var.management.security_contact, null)
  security_center_settings              = try(var.management.security_center_settings, {})
  defender_soc_posture                  = try(var.management.defender_soc_posture, { enabled = false })
}
