output "resource_group_name" {
  value = module.resource_group.name
}

output "log_analytics_workspace_id" {
  value = module.log_analytics.id
}

output "log_analytics_workspace_guid" {
  value = module.log_analytics.workspace_id
}

output "action_group_id" {
  value = module.action_group.id
}

output "resource_provider_registration_ids" {
  value = { for key, value in azurerm_resource_provider_registration.this : key => value.id }
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
  value = { for key, value in azurerm_consumption_budget_subscription.this : key => value.id }
}

output "management_lock_ids" {
  value = { for key, value in azurerm_management_lock.this : key => value.id }
}

output "defender_plan_ids" {
  value = { for key, value in azurerm_security_center_subscription_pricing.this : key => value.id }
}

output "defender_soc_posture" {
  value = {
    enabled                       = try(var.defender_soc_posture.enabled, false)
    defender_standard_enabled     = try(var.defender_soc_posture.defender_standard_enabled, false)
    sentinel_enabled              = try(var.defender_soc_posture.sentinel_enabled, false)
    data_collection_rules_enabled = try(var.defender_soc_posture.data_collection_rules_enabled, false)
    security_contact_enabled      = try(var.defender_soc_posture.security_contact_enabled, false)
    notes                         = try(var.defender_soc_posture.notes, null)
  }
}
