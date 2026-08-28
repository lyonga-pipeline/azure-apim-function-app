output "management_group_ids" {
  description = "Management group IDs keyed by governance catalog key."
  value       = try(module.governance[0].management_group_ids, {})
}

output "custom_policy_definition_ids" {
  value = try(module.governance[0].custom_policy_definition_ids, {})
}

output "custom_policy_set_definition_ids" {
  value = try(module.governance[0].custom_policy_set_definition_ids, {})
}

output "management_group_policy_assignment_ids" {
  value = try(module.governance[0].management_group_policy_assignment_ids, {})
}

output "subscription_policy_assignment_ids" {
  value = try(module.governance[0].subscription_policy_assignment_ids, {})
}

output "custom_role_definition_ids" {
  value = try(module.governance[0].custom_role_definition_ids, {})
}

output "role_assignment_ids" {
  value = try(module.governance[0].role_assignment_ids, {})
}
