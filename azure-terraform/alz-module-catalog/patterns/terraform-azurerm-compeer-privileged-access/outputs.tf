output "pim_eligible_role_assignment_ids" {
  description = "PIM eligible role assignment resource IDs keyed by pim_eligible_role_assignments key."
  value       = { for key, assignment in azurerm_pim_eligible_role_assignment.this : key => assignment.id }
}

output "break_glass_alert_id" {
  description = "Resource ID of the break-glass sign-in alert rule, or null when disabled."
  value       = try(azurerm_monitor_scheduled_query_rules_alert_v2.break_glass_signin[0].id, null)
}

output "role_management_policy_ids" {
  description = "PIM activation-policy resource IDs keyed by role_management_policies key."
  value       = module.role_management_policies.ids
}

output "operational_contracts" {
  description = "Declared privileged-access operational controls that are not provisioned here."
  value       = module.operational_contracts.contracts
}

output "manual_control_keys" {
  description = "Privileged-access controls deliberately left outside Terraform (admin Conditional Access, PAW)."
  value       = module.operational_contracts.manual_control_keys
}
