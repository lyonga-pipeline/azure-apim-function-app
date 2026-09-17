output "resource_group_name" {
  value = module.resource_group.name
}

output "diagnostic_profile" {
  description = "Platform_Output_Contracts_IAC-10 management_diagnostic_profile - the platform's canonical default diagnostic-settings profile (see modules/terraform-azurerm-compeer-diagnostic-profile for what this recommends vs. enforces)."
  value       = module.diagnostic_profile.profile
}

output "log_analytics_workspace_id" {
  value = module.log_analytics.id
}

output "log_analytics_workspace_name" {
  value = module.log_analytics.name
}

output "log_analytics_workspace_guid" {
  value = module.log_analytics.workspace_id
}

output "log_analytics_workspace_ids" {
  description = "Platform_Output_Contracts_IAC-10 management_log_analytics_workspace_ids - map(string) keyed by environment. v7 sec 9.2 wants one centralised workspace per environment; the real deployment today is one platform workspace - that conflict is unresolved (per the contract doc sec 7), so this map absorbs either outcome without a breaking change later: with one workspace, the map just has one key that every environment resolves to."
  value       = { (var.environment) = module.log_analytics.id }
}

output "log_analytics_workspace_guids" {
  description = "Platform_Output_Contracts_IAC-10 management_log_analytics_workspace_guids - map(string) keyed by environment, same rationale as log_analytics_workspace_ids."
  value       = { (var.environment) = module.log_analytics.workspace_id }
}

output "log_analytics_workspace_resource_group_name" {
  value = module.log_analytics.resource_group_name
}

output "log_analytics_workspace_location" {
  value = module.log_analytics.location
}

output "log_analytics_identity_principal_id" {
  value = module.log_analytics.identity_principal_id
}

output "log_analytics_contributor_assignment_ids" {
  value = module.log_analytics_contributor_role_assignments.ids
}

output "log_analytics_security_center_workspace_ids" {
  value = { for key, value in azurerm_security_center_workspace.log_analytics : key => value.id }
}

output "action_group_id" {
  value = module.action_group.id
}

output "action_group_name" {
  value = module.action_group.name
}

output "action_group_enabled" {
  value = module.action_group.enabled
}

output "action_group_ids" {
  description = "Platform_Output_Contracts_IAC-10 management_action_group_ids. The design doc's OBS-04 keys this by severity and audience (multiple groups) - that's Phase 2; today there's one action group, so this is a single-key map (\"primary\") for forward compatibility. Not the reserved-empty-map placeholder the contract doc describes for an undelivered OBS-04, since a real action group already exists here."
  value       = { primary = module.action_group.id }
}

output "platform_storage_account_ids" {
  value = { for key, value in module.platform_storage_accounts : key => value.id }
}

output "platform_storage_account_names" {
  value = { for key, value in module.platform_storage_accounts : key => value.name }
}

output "platform_storage_account_blob_endpoints" {
  value = { for key, value in module.platform_storage_accounts : key => value.primary_blob_endpoint }
}

output "platform_storage_account_primary_endpoints" {
  value = { for key, value in module.platform_storage_accounts : key => value.primary_endpoints }
}

output "platform_storage_account_private_endpoint_subresources" {
  value = { for key, value in module.platform_storage_accounts : key => value.private_endpoint_ready_subresource_names }
}

output "platform_storage_diagnostic_setting_ids" {
  value = { for key, value in module.platform_storage_diagnostics : key => value.id }
}

output "platform_key_vault_ids" {
  value = { for key, value in module.platform_key_vaults : key => value.id }
}

output "platform_key_vault_names" {
  value = { for key, value in module.platform_key_vaults : key => value.name }
}

output "platform_key_vault_uris" {
  value = { for key, value in module.platform_key_vaults : key => value.vault_uri }
}

output "platform_key_vault_private_endpoint_subresources" {
  value = { for key, value in module.platform_key_vaults : key => [value.private_endpoint_subresource_name] }
}

output "platform_key_vault_diagnostic_setting_ids" {
  value = { for key, value in module.platform_key_vault_diagnostics : key => value.id }
}

output "platform_storage_private_endpoint_ids" {
  value = { for key, value in module.platform_storage_private_endpoints : key => value.id }
}

output "platform_storage_private_endpoints" {
  value = {
    for key, value in module.platform_storage_private_endpoints : key => {
      id                         = value.id
      name                       = value.name
      resource_group_name        = value.resource_group_name
      subnet_id                  = value.subnet_id
      private_service_connection = value.private_service_connection
      private_dns_zone_configs   = value.private_dns_zone_configs
    }
  }
}

output "platform_key_vault_private_endpoint_ids" {
  value = { for key, value in module.platform_key_vault_private_endpoints : key => value.id }
}

output "platform_key_vault_private_endpoints" {
  value = {
    for key, value in module.platform_key_vault_private_endpoints : key => {
      id                         = value.id
      name                       = value.name
      resource_group_name        = value.resource_group_name
      subnet_id                  = value.subnet_id
      private_service_connection = value.private_service_connection
      private_dns_zone_configs   = value.private_dns_zone_configs
    }
  }
}

output "recovery_services_vault_ids" {
  value = { for key, value in module.recovery_services_vaults : key => value.id }
}

output "recovery_services_vault_names" {
  value = { for key, value in module.recovery_services_vaults : key => value.name }
}

output "recovery_services_vault_diagnostic_setting_ids" {
  value = { for key, value in module.recovery_services_vault_diagnostics : key => value.id }
}

output "backup_policy_vm_ids" {
  description = "VM backup policy IDs keyed `<vault_key>.<tier>` (feed to workload / DC patterns for protected-item enrolment)."
  value = merge([
    for vkey, v in module.recovery_services_vaults :
    { for tier, id in v.backup_policy_vm_ids : "${vkey}.${tier}" => id }
  ]...)
}

output "backup_policy_file_share_ids" {
  description = "File share backup policy IDs keyed `<vault_key>.<tier>`."
  value = merge([
    for vkey, v in module.recovery_services_vaults :
    { for tier, id in v.backup_policy_file_share_ids : "${vkey}.${tier}" => id }
  ]...)
}

output "data_collection_endpoint_ids" {
  value = { for key, value in module.data_collection_endpoints : key => value.id }
}

output "data_collection_endpoints" {
  value = {
    for key, value in module.data_collection_endpoints : key => {
      id                            = value.id
      name                          = value.name
      immutable_id                  = value.immutable_id
      configuration_access_endpoint = value.configuration_access_endpoint
      logs_ingestion_endpoint       = value.logs_ingestion_endpoint
      metrics_ingestion_endpoint    = value.metrics_ingestion_endpoint
    }
  }
}

output "data_collection_rule_ids" {
  value = { for key, value in module.data_collection_rules : key => value.id }
}

output "data_collection_rule_association_ids" {
  value = { for key, value in module.data_collection_rule_associations : key => value.id }
}

output "sentinel_onboarding_id" {
  value = module.sentinel.onboarding_id
}

output "sentinel_data_connector_contract" {
  value = module.sentinel.data_connector_contract
}

output "resource_provider_registration_ids" {
  value = { for key, value in azurerm_resource_provider_registration.registration : key => value.id }
}

output "role_assignment_ids" {
  value = module.role_assignments.ids
}

output "subscription_activity_log_diagnostic_setting_id" {
  value = try(azurerm_monitor_diagnostic_setting.subscription_activity_log[0].id, null)
}

output "entra_diagnostic_setting_id" {
  value = try(azurerm_monitor_aad_diagnostic_setting.entra[0].id, null)
}

output "subscription_budget_ids" {
  value = { for key, value in azurerm_consumption_budget_subscription.subscription_budget : key => value.id }
}

output "management_lock_ids" {
  value = module.management_locks.ids
}

output "defender_plan_ids" {
  value = { for key, value in azurerm_security_center_subscription_pricing.pricing : key => value.id }
}

output "defender_soc_posture" {
  value = terraform_data.defender_soc_posture_contract.output
}

output "platform_metric_alert_ids" {
  value = { for k, v in module.platform_metric_alerts : k => v.id }
}

output "service_health_alert_id" {
  value = try(azurerm_monitor_activity_log_alert.service_health[0].id, null)
}
