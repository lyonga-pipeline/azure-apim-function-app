output "pim_eligible_role_assignment_ids" {
  description = "PIM eligible role assignment resource IDs keyed by pim_eligible_role_assignments key."
  value       = try(module.privileged_access[0].pim_eligible_role_assignment_ids, {})
}

output "role_management_policy_ids" {
  description = "PIM activation-policy resource IDs keyed by role_management_policies key."
  value       = try(module.privileged_access[0].role_management_policy_ids, {})
}

output "break_glass_alert_id" {
  description = "Resource ID of the break-glass sign-in alert rule, or null when disabled."
  value       = try(module.privileged_access[0].break_glass_alert_id, null)
}

output "operational_contracts" {
  description = "Declared privileged-access operational controls that are not provisioned here."
  value       = try(module.privileged_access[0].operational_contracts, {})
}

output "manual_control_keys" {
  description = "Privileged-access controls tracked here but deliberately not Terraform-managed."
  value       = try(module.privileged_access[0].manual_control_keys, [])
}
