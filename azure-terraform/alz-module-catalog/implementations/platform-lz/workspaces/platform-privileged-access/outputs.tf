output "pim_eligible_role_assignment_ids" {
  value = try(module.privileged_access[0].pim_eligible_role_assignment_ids, {})
}

output "role_management_policy_ids" {
  value = try(module.privileged_access[0].role_management_policy_ids, {})
}

output "break_glass_alert_id" {
  value = try(module.privileged_access[0].break_glass_alert_id, null)
}

output "operational_contracts" {
  value = try(module.privileged_access[0].operational_contracts, {})
}

output "manual_control_keys" {
  description = "Privileged-access controls tracked here but deliberately not Terraform-managed."
  value       = try(module.privileged_access[0].manual_control_keys, [])
}
