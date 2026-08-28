output "pim_eligible_assignment_ids" {
  value = { for key, assignment in azurerm_pim_eligible_role_assignment.this : key => assignment.id }
}

output "break_glass_signin_alert_id" {
  value = try(azurerm_monitor_scheduled_query_rules_alert_v2.break_glass_signin[0].id, null)
}

output "operational_contracts" {
  value = module.operational_contracts.contracts
}
