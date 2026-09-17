output "resource_group_name" {
  description = "Name of the platform-management resource group."
  value       = module.resource_group.name
}

output "diagnostic_profile" {
  description = "Platform_Output_Contracts_IAC-10 management_diagnostic_profile - the platform's canonical default diagnostic-settings profile (see modules/terraform-azurerm-compeer-diagnostic-profile for what this recommends vs. enforces)."
  value       = module.diagnostic_profile.profile
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the platform Log Analytics workspace."
  value       = module.log_analytics.id
}

output "log_analytics_workspace_name" {
  description = "Name of the platform Log Analytics workspace."
  value       = module.log_analytics.name
}

output "log_analytics_workspace_guid" {
  description = "Workspace GUID (Customer ID) of the platform Log Analytics workspace, distinct from its resource ID - required by agents/DCRs that authenticate by workspace GUID."
  value       = module.log_analytics.workspace_id
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
  description = "Resource group name containing the platform Log Analytics workspace."
  value       = module.log_analytics.resource_group_name
}

output "log_analytics_workspace_location" {
  description = "Azure region of the platform Log Analytics workspace."
  value       = module.log_analytics.location
}

output "log_analytics_identity_principal_id" {
  description = "Principal ID of the Log Analytics workspace's system-assigned managed identity, if enabled."
  value       = module.log_analytics.identity_principal_id
}

output "log_analytics_contributor_assignment_ids" {
  description = "IDs of the role assignments granting Log Analytics Contributor on the workspace."
  value       = module.log_analytics_contributor_role_assignments.ids
}

output "log_analytics_security_center_workspace_ids" {
  description = "IDs of the azurerm_security_center_workspace links connecting Defender for Cloud to this Log Analytics workspace, keyed by pricing tier/subplan."
  value       = { for key, value in azurerm_security_center_workspace.log_analytics : key => value.id }
}

output "action_group_id" {
  description = "Resource ID of the platform's primary Azure Monitor action group."
  value       = module.action_group.id
}

output "action_group_name" {
  description = "Name of the platform's primary Azure Monitor action group."
  value       = module.action_group.name
}

output "action_group_enabled" {
  description = "Whether the platform's primary action group is enabled."
  value       = module.action_group.enabled
}

output "action_group_ids" {
  description = "Platform_Output_Contracts_IAC-10 management_action_group_ids. The design doc's OBS-04 keys this by severity and audience (multiple groups) - that's Phase 2; today there's one action group, so this is a single-key map (\"primary\") for forward compatibility. Not the reserved-empty-map placeholder the contract doc describes for an undelivered OBS-04, since a real action group already exists here."
  value       = { primary = module.action_group.id }
}

output "platform_storage_account_ids" {
  description = "Resource IDs of the platform storage accounts, keyed the same as var.platform_storage_accounts."
  value       = { for key, value in module.platform_storage_accounts : key => value.id }
}

output "platform_storage_account_names" {
  description = "Names of the platform storage accounts, keyed the same as var.platform_storage_accounts."
  value       = { for key, value in module.platform_storage_accounts : key => value.name }
}

output "platform_storage_account_blob_endpoints" {
  description = "Primary blob service endpoints of the platform storage accounts, keyed the same as var.platform_storage_accounts."
  value       = { for key, value in module.platform_storage_accounts : key => value.primary_blob_endpoint }
}

output "platform_storage_account_primary_endpoints" {
  description = "Full set of primary service endpoints (blob/queue/table/file) per platform storage account, keyed the same as var.platform_storage_accounts."
  value       = { for key, value in module.platform_storage_accounts : key => value.primary_endpoints }
}

output "platform_storage_account_private_endpoint_subresources" {
  description = "Private-endpoint-ready subresource names (e.g. blob, file) exposed by each platform storage account, keyed the same as var.platform_storage_accounts - feeds the private endpoint modules below."
  value       = { for key, value in module.platform_storage_accounts : key => value.private_endpoint_ready_subresource_names }
}

output "platform_storage_diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings on the platform storage accounts, keyed the same as var.platform_storage_diagnostics."
  value       = { for key, value in module.platform_storage_diagnostics : key => value.id }
}

output "platform_key_vault_ids" {
  description = "Resource IDs of the platform Key Vaults, keyed the same as var.platform_key_vaults."
  value       = { for key, value in module.platform_key_vaults : key => value.id }
}

output "platform_key_vault_names" {
  description = "Names of the platform Key Vaults, keyed the same as var.platform_key_vaults."
  value       = { for key, value in module.platform_key_vaults : key => value.name }
}

output "platform_key_vault_uris" {
  description = "Vault URIs of the platform Key Vaults, keyed the same as var.platform_key_vaults. Reference only, never a secret value."
  value       = { for key, value in module.platform_key_vaults : key => value.vault_uri }
}

output "platform_key_vault_private_endpoint_subresources" {
  description = "Private-endpoint subresource names (always [\"vault\"]) per platform Key Vault, keyed the same as var.platform_key_vaults - feeds the private endpoint module below."
  value       = { for key, value in module.platform_key_vaults : key => [value.private_endpoint_subresource_name] }
}

output "platform_key_vault_diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings on the platform Key Vaults, keyed the same as var.platform_key_vault_diagnostics."
  value       = { for key, value in module.platform_key_vault_diagnostics : key => value.id }
}

output "platform_storage_private_endpoint_ids" {
  description = "Resource IDs of the private endpoints created for the platform storage accounts, keyed the same as their private endpoint configuration."
  value       = { for key, value in module.platform_storage_private_endpoints : key => value.id }
}

output "platform_storage_private_endpoints" {
  description = "Full detail (id, name, resource group, subnet, service connection, DNS zone config) for each platform storage account private endpoint, keyed the same as their private endpoint configuration."
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
  description = "Resource IDs of the private endpoints created for the platform Key Vaults, keyed the same as their private endpoint configuration."
  value       = { for key, value in module.platform_key_vault_private_endpoints : key => value.id }
}

output "platform_key_vault_private_endpoints" {
  description = "Full detail (id, name, resource group, subnet, service connection, DNS zone config) for each platform Key Vault private endpoint, keyed the same as their private endpoint configuration."
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
  description = "Resource IDs of the Recovery Services Vaults, keyed the same as var.recovery_services_vaults (this catalog's vault/purpose keying - see Platform_Output_Contracts_IAC-10 management_recovery_services_vault_ids)."
  value       = { for key, value in module.recovery_services_vaults : key => value.id }
}

output "recovery_services_vault_names" {
  description = "Names of the Recovery Services Vaults, keyed the same as var.recovery_services_vaults."
  value       = { for key, value in module.recovery_services_vaults : key => value.name }
}

output "recovery_services_vault_diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings on the Recovery Services Vaults, keyed the same as var.recovery_services_vault_diagnostics."
  value       = { for key, value in module.recovery_services_vault_diagnostics : key => value.id }
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
  description = "Resource IDs of the Azure Monitor Data Collection Endpoints, keyed the same as var.data_collection_endpoints."
  value       = { for key, value in module.data_collection_endpoints : key => value.id }
}

output "data_collection_endpoints" {
  description = "Full detail (id, name, immutable_id, configuration/logs/metrics ingestion endpoints) for each Data Collection Endpoint, keyed the same as var.data_collection_endpoints."
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
  description = "Resource IDs of the Azure Monitor Data Collection Rules, keyed the same as var.data_collection_rules."
  value       = { for key, value in module.data_collection_rules : key => value.id }
}

output "data_collection_rule_association_ids" {
  description = "Resource IDs of the Data Collection Rule associations, keyed the same as var.data_collection_rule_associations."
  value       = { for key, value in module.data_collection_rule_associations : key => value.id }
}

output "sentinel_onboarding_id" {
  description = "Resource ID of the Microsoft Sentinel onboarding state for this Log Analytics workspace. Platform_Output_Contracts_IAC-10 security_sentinel_workspace_id maps here (see platform-security split note)."
  value       = module.sentinel.onboarding_id
}

output "sentinel_data_connector_contract" {
  description = "Sentinel data connector contract object published by module.sentinel - see that module's own docs for shape."
  value       = module.sentinel.data_connector_contract
}

output "resource_provider_registration_ids" {
  description = "IDs of the explicit azurerm_resource_provider_registration resources this pattern manages, keyed by provider namespace."
  value       = { for key, value in azurerm_resource_provider_registration.registration : key => value.id }
}

output "role_assignment_ids" {
  description = "IDs of the role assignments this pattern creates, keyed the same as var.role_assignments."
  value       = module.role_assignments.ids
}

output "subscription_activity_log_diagnostic_setting_id" {
  description = "ID of the subscription-level Activity Log diagnostic setting routing to this Log Analytics workspace, or null if not enabled."
  value       = try(azurerm_monitor_diagnostic_setting.subscription_activity_log[0].id, null)
}

output "entra_diagnostic_setting_id" {
  description = "ID of the Entra ID (Azure AD) tenant diagnostic setting routing to this Log Analytics workspace, or null if not enabled - requires tenant-level permissions to create."
  value       = try(azurerm_monitor_aad_diagnostic_setting.entra[0].id, null)
}

output "subscription_budget_ids" {
  description = "IDs of the subscription consumption budgets this pattern creates, keyed the same as var.subscription_budgets."
  value       = { for key, value in azurerm_consumption_budget_subscription.subscription_budget : key => value.id }
}

output "management_lock_ids" {
  description = "IDs of the management locks (CanNotDelete/ReadOnly) this pattern applies, keyed the same as var.management_locks."
  value       = module.management_locks.ids
}

output "defender_plan_ids" {
  description = "IDs of the Microsoft Defender for Cloud pricing-tier subscriptions this pattern enables, keyed by plan/resource type. Platform_Output_Contracts_IAC-10 security_defender_enabled_plans maps here."
  value       = { for key, value in azurerm_security_center_subscription_pricing.pricing : key => value.id }
}

output "defender_soc_posture" {
  description = "Defender/SOC posture contract object (see the defender_soc_posture_contract terraform_data resource for what it asserts)."
  value       = terraform_data.defender_soc_posture_contract.output
}

output "platform_metric_alert_ids" {
  description = "Resource IDs of the platform metric alerts, keyed the same as var.platform_metric_alerts."
  value       = { for k, v in module.platform_metric_alerts : k => v.id }
}

output "service_health_alert_id" {
  description = "ID of the subscription-level Service Health activity log alert, or null if not enabled."
  value       = try(azurerm_monitor_activity_log_alert.service_health[0].id, null)
}
