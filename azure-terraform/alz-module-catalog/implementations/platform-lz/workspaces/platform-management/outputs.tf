output "resource_group_name" {
  value = try(module.management[0].resource_group_name, null)
}

output "log_analytics_workspace_id" {
  value = try(module.management[0].log_analytics_workspace_id, null)
}

output "log_analytics_workspace_name" {
  value = try(module.management[0].log_analytics_workspace_name, null)
}

output "log_analytics_workspace_guid" {
  value = try(module.management[0].log_analytics_workspace_guid, null)
}

output "log_analytics_workspace_resource_group_name" {
  value = try(module.management[0].log_analytics_workspace_resource_group_name, null)
}

output "log_analytics_workspace_location" {
  value = try(module.management[0].log_analytics_workspace_location, null)
}

output "log_analytics_identity_principal_id" {
  value = try(module.management[0].log_analytics_identity_principal_id, null)
}

output "log_analytics_contributor_assignment_ids" {
  value = try(module.management[0].log_analytics_contributor_assignment_ids, {})
}

output "log_analytics_security_center_workspace_ids" {
  value = try(module.management[0].log_analytics_security_center_workspace_ids, {})
}

output "action_group_id" {
  value = try(module.management[0].action_group_id, null)
}

output "action_group_name" {
  value = try(module.management[0].action_group_name, null)
}

output "action_group_enabled" {
  value = try(module.management[0].action_group_enabled, null)
}

output "platform_storage_account_ids" {
  value = try(module.management[0].platform_storage_account_ids, {})
}

output "platform_storage_account_names" {
  value = try(module.management[0].platform_storage_account_names, {})
}

output "platform_storage_account_primary_endpoints" {
  value = try(module.management[0].platform_storage_account_primary_endpoints, {})
}

output "platform_storage_private_endpoints" {
  value = try(module.management[0].platform_storage_private_endpoints, {})
}

output "platform_storage_diagnostic_setting_ids" {
  value = try(module.management[0].platform_storage_diagnostic_setting_ids, {})
}

output "platform_storage_private_endpoint_ids" {
  value = try(module.management[0].platform_storage_private_endpoint_ids, {})
}

output "platform_key_vault_ids" {
  value = try(module.management[0].platform_key_vault_ids, {})
}

output "platform_key_vault_names" {
  value = try(module.management[0].platform_key_vault_names, {})
}

output "platform_key_vault_uris" {
  value = try(module.management[0].platform_key_vault_uris, {})
}

output "platform_key_vault_private_endpoints" {
  value = try(module.management[0].platform_key_vault_private_endpoints, {})
}

output "platform_key_vault_private_endpoint_ids" {
  value = try(module.management[0].platform_key_vault_private_endpoint_ids, {})
}

output "platform_key_vault_diagnostic_setting_ids" {
  value = try(module.management[0].platform_key_vault_diagnostic_setting_ids, {})
}

output "recovery_services_vault_ids" {
  value = try(module.management[0].recovery_services_vault_ids, {})
}

output "recovery_services_vault_names" {
  value = try(module.management[0].recovery_services_vault_names, {})
}

output "recovery_services_vault_diagnostic_setting_ids" {
  value = try(module.management[0].recovery_services_vault_diagnostic_setting_ids, {})
}

output "data_collection_endpoint_ids" {
  value = try(module.management[0].data_collection_endpoint_ids, {})
}

output "data_collection_endpoints" {
  value = try(module.management[0].data_collection_endpoints, {})
}

output "data_collection_rule_ids" {
  value = try(module.management[0].data_collection_rule_ids, {})
}

output "data_collection_rule_association_ids" {
  value = try(module.management[0].data_collection_rule_association_ids, {})
}

output "sentinel_onboarding_id" {
  value = try(module.management[0].sentinel_onboarding_id, null)
}

output "sentinel_data_connector_contract" {
  value = try(module.management[0].sentinel_data_connector_contract, null)
}

output "defender_soc_posture" {
  value = try(module.management[0].defender_soc_posture, null)
}
