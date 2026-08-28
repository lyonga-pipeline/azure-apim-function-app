output "custom_policy_definition_ids" {
  value = local.policy_definition_ids
}

output "custom_policy_set_definition_ids" {
  value = local.policy_set_definition_ids
}

output "management_group_policy_assignment_ids" {
  value = { for key, value in azurerm_management_group_policy_assignment.this : key => value.id }
}

output "subscription_policy_assignment_ids" {
  value = { for key, value in azurerm_subscription_policy_assignment.this : key => value.id }
}
