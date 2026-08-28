output "log_analytics_workspace_id" { value = module.log_analytics.resource_id }
output "platform_key_vault_id" { value = module.key_vault.id }
output "platform_storage_account_id" { value = module.platform_storage.id }
output "platform_uami_id" { value = module.platform_identity.resource_id }
output "management_resource_group_name" { value = module.resource_groups["management"].name }
output "security_resource_group_name" { value = module.resource_groups["security"].name }
output "sentinel_onboarding_id" { value = module.sentinel.onboarding_id }
output "defender_plan_ids" { value = module.defender_soc_posture.defender_plan_ids }
