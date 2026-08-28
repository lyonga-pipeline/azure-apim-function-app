output "custom_policy_definition_ids" {
  value = try(module.policy[0].custom_policy_definition_ids, {})
}

output "custom_policy_set_definition_ids" {
  value = try(module.policy[0].custom_policy_set_definition_ids, {})
}

output "management_group_policy_assignment_ids" {
  value = try(module.policy[0].management_group_policy_assignment_ids, {})
}

output "subscription_policy_assignment_ids" {
  value = try(module.policy[0].subscription_policy_assignment_ids, {})
}
