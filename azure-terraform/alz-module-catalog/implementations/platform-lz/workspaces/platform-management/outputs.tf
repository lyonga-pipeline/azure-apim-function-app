output "resource_group_name" {
  description = "Name of the platform-management resource group."
  value       = try(module.management[0].resource_group_name, null)
}

output "diagnostic_profile" {
  description = "Platform_Output_Contracts_IAC-10 management_diagnostic_profile."
  value       = try(module.management[0].diagnostic_profile, null)
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the platform Log Analytics workspace."
  value       = try(module.management[0].log_analytics_workspace_id, null)
}

output "log_analytics_workspace_name" {
  description = "Name of the platform Log Analytics workspace."
  value       = try(module.management[0].log_analytics_workspace_name, null)
}

output "log_analytics_workspace_guid" {
  description = "Workspace GUID (Customer ID) of the platform Log Analytics workspace."
  value       = try(module.management[0].log_analytics_workspace_guid, null)
}

output "log_analytics_workspace_ids" {
  description = "Platform_Output_Contracts_IAC-10 management_log_analytics_workspace_ids."
  value       = try(module.management[0].log_analytics_workspace_ids, {})
}

output "log_analytics_workspace_guids" {
  description = "Platform_Output_Contracts_IAC-10 management_log_analytics_workspace_guids."
  value       = try(module.management[0].log_analytics_workspace_guids, {})
}

output "log_analytics_workspace_resource_group_name" {
  description = "Resource group name containing the platform Log Analytics workspace."
  value       = try(module.management[0].log_analytics_workspace_resource_group_name, null)
}

output "log_analytics_workspace_location" {
  description = "Azure region of the platform Log Analytics workspace."
  value       = try(module.management[0].log_analytics_workspace_location, null)
}

output "log_analytics_identity_principal_id" {
  description = "Principal ID of the Log Analytics workspace's system-assigned managed identity, if enabled."
  value       = try(module.management[0].log_analytics_identity_principal_id, null)
}

output "log_analytics_contributor_assignment_ids" {
  description = "IDs of the role assignments granting Log Analytics Contributor on the workspace."
  value       = try(module.management[0].log_analytics_contributor_assignment_ids, {})
}

output "log_analytics_security_center_workspace_ids" {
  description = "IDs of the Defender for Cloud <-> Log Analytics workspace links, keyed by pricing tier/subplan."
  value       = try(module.management[0].log_analytics_security_center_workspace_ids, {})
}

output "action_group_id" {
  description = "Resource ID of the platform's primary Azure Monitor action group."
  value       = try(module.management[0].action_group_id, null)
}

output "action_group_name" {
  description = "Name of the platform's primary Azure Monitor action group."
  value       = try(module.management[0].action_group_name, null)
}

output "action_group_enabled" {
  description = "Whether the platform's primary action group is enabled."
  value       = try(module.management[0].action_group_enabled, null)
}

output "action_group_ids" {
  description = "Platform_Output_Contracts_IAC-10 management_action_group_ids."
  value       = try(module.management[0].action_group_ids, {})
}

output "defender_plan_ids" {
  description = "Platform_Output_Contracts_IAC-10 security_defender_enabled_plans."
  value       = try(module.management[0].defender_plan_ids, {})
}

output "platform_storage_account_ids" {
  description = "Platform_Output_Contracts_IAC-10 management_platform_storage_account_ids."
  value       = try(module.management[0].platform_storage_account_ids, {})
}

output "platform_storage_account_names" {
  description = "Names of the platform storage accounts, keyed the same as platform_storage_account_ids."
  value       = try(module.management[0].platform_storage_account_names, {})
}

output "platform_storage_account_blob_endpoints" {
  description = "Primary blob service endpoints of the platform storage accounts, keyed the same as platform_storage_account_ids."
  value       = try(module.management[0].platform_storage_account_blob_endpoints, {})
}

output "platform_storage_account_primary_endpoints" {
  description = "Full set of primary service endpoints per platform storage account, keyed the same as platform_storage_account_ids."
  value       = try(module.management[0].platform_storage_account_primary_endpoints, {})
}

output "platform_storage_account_private_endpoint_subresources" {
  description = "Private-endpoint-ready subresource names per platform storage account, keyed the same as platform_storage_account_ids."
  value       = try(module.management[0].platform_storage_account_private_endpoint_subresources, {})
}

output "platform_storage_private_endpoints" {
  description = "Full detail for each platform storage account private endpoint."
  value       = try(module.management[0].platform_storage_private_endpoints, {})
}

output "platform_storage_diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings on the platform storage accounts."
  value       = try(module.management[0].platform_storage_diagnostic_setting_ids, {})
}

output "platform_storage_private_endpoint_ids" {
  description = "Resource IDs of the private endpoints created for the platform storage accounts."
  value       = try(module.management[0].platform_storage_private_endpoint_ids, {})
}

output "platform_key_vault_ids" {
  description = "Resource IDs of the platform Key Vaults."
  value       = try(module.management[0].platform_key_vault_ids, {})
}

output "platform_key_vault_names" {
  description = "Names of the platform Key Vaults, keyed the same as platform_key_vault_ids."
  value       = try(module.management[0].platform_key_vault_names, {})
}

output "platform_key_vault_uris" {
  description = "Vault URIs of the platform Key Vaults. Reference only, never a secret value."
  value       = try(module.management[0].platform_key_vault_uris, {})
}

output "platform_key_vault_private_endpoint_subresources" {
  description = "Private-endpoint subresource names per platform Key Vault, keyed the same as platform_key_vault_ids."
  value       = try(module.management[0].platform_key_vault_private_endpoint_subresources, {})
}

output "platform_key_vault_private_endpoints" {
  description = "Full detail for each platform Key Vault private endpoint."
  value       = try(module.management[0].platform_key_vault_private_endpoints, {})
}

output "platform_key_vault_private_endpoint_ids" {
  description = "Resource IDs of the private endpoints created for the platform Key Vaults."
  value       = try(module.management[0].platform_key_vault_private_endpoint_ids, {})
}

output "platform_key_vault_diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings on the platform Key Vaults."
  value       = try(module.management[0].platform_key_vault_diagnostic_setting_ids, {})
}

output "recovery_services_vault_ids" {
  description = "Platform_Output_Contracts_IAC-10 management_recovery_services_vault_ids."
  value       = try(module.management[0].recovery_services_vault_ids, {})
}

output "backup_policy_vm_ids" {
  description = "VM backup policy IDs keyed <vault>.<tier> - feed to workload / directory-services patterns."
  value       = try(module.management[0].backup_policy_vm_ids, {})
}

output "backup_policy_file_share_ids" {
  description = "File share backup policy IDs keyed <vault>.<tier>."
  value       = try(module.management[0].backup_policy_file_share_ids, {})
}

output "recovery_services_vault_names" {
  description = "Names of the Recovery Services Vaults, keyed the same as recovery_services_vault_ids."
  value       = try(module.management[0].recovery_services_vault_names, {})
}

output "recovery_services_vault_diagnostic_setting_ids" {
  description = "IDs of the diagnostic settings on the Recovery Services Vaults."
  value       = try(module.management[0].recovery_services_vault_diagnostic_setting_ids, {})
}

output "data_collection_endpoint_ids" {
  description = "Resource IDs of the Azure Monitor Data Collection Endpoints."
  value       = try(module.management[0].data_collection_endpoint_ids, {})
}

output "data_collection_endpoints" {
  description = "Full detail for each Data Collection Endpoint (ingestion endpoints, immutable_id)."
  value       = try(module.management[0].data_collection_endpoints, {})
}

output "data_collection_rule_ids" {
  description = "Resource IDs of the Azure Monitor Data Collection Rules."
  value       = try(module.management[0].data_collection_rule_ids, {})
}

output "data_collection_rule_association_ids" {
  description = "Resource IDs of the Data Collection Rule associations."
  value       = try(module.management[0].data_collection_rule_association_ids, {})
}

output "sentinel_onboarding_id" {
  description = "Resource ID of the Microsoft Sentinel onboarding state for this Log Analytics workspace. Platform_Output_Contracts_IAC-10 security_sentinel_workspace_id maps here."
  value       = try(module.management[0].sentinel_onboarding_id, null)
}

output "sentinel_data_connector_contract" {
  description = "Sentinel data connector contract object - see module.sentinel's own docs for shape."
  value       = try(module.management[0].sentinel_data_connector_contract, null)
}

output "resource_provider_registration_ids" {
  description = "IDs of the explicit resource provider registrations this pattern manages, keyed by provider namespace."
  value       = try(module.management[0].resource_provider_registration_ids, {})
}

output "role_assignment_ids" {
  description = "IDs of the role assignments this pattern creates."
  value       = try(module.management[0].role_assignment_ids, {})
}

output "subscription_activity_log_diagnostic_setting_id" {
  description = "ID of the subscription-level Activity Log diagnostic setting routing to this Log Analytics workspace, or null if not enabled."
  value       = try(module.management[0].subscription_activity_log_diagnostic_setting_id, null)
}

output "entra_diagnostic_setting_id" {
  description = "ID of the Entra ID (Azure AD) tenant diagnostic setting routing to this Log Analytics workspace, or null if not enabled."
  value       = try(module.management[0].entra_diagnostic_setting_id, null)
}

output "subscription_budget_ids" {
  description = "IDs of the subscription consumption budgets this pattern creates."
  value       = try(module.management[0].subscription_budget_ids, {})
}

output "management_lock_ids" {
  description = "IDs of the management locks (CanNotDelete/ReadOnly) this pattern applies."
  value       = try(module.management[0].management_lock_ids, {})
}

output "platform_metric_alert_ids" {
  description = "Resource IDs of the platform metric alerts."
  value       = try(module.management[0].platform_metric_alert_ids, {})
}

output "service_health_alert_id" {
  description = "ID of the subscription-level Service Health activity log alert, or null if not enabled."
  value       = try(module.management[0].service_health_alert_id, null)
}

output "defender_soc_posture" {
  description = "Defender/SOC posture contract object."
  value       = try(module.management[0].defender_soc_posture, null)
}

output "contract_version" {
  description = "Platform_Output_Contracts_IAC-10 management_contract_version."
  value       = "0.1.0"
}
