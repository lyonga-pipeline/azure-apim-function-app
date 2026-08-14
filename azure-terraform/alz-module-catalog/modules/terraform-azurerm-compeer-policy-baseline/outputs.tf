output "policy_definition_ids" {
  description = "Custom policy definition IDs keyed by input key."
  value       = local.policy_definition_ids
}

output "policy_set_definition_ids" {
  description = "Policy initiative IDs keyed by input key."
  value       = local.policy_set_ids
}

output "management_group_assignment_ids" {
  description = "Management group policy assignment IDs keyed by input key."
  value       = { for key, assignment in azurerm_management_group_policy_assignment.this : key => assignment.id }
}

output "subscription_assignment_ids" {
  description = "Subscription policy assignment IDs keyed by input key."
  value       = { for key, assignment in azurerm_subscription_policy_assignment.this : key => assignment.id }
}

output "resource_group_assignment_ids" {
  description = "Resource group policy assignment IDs keyed by input key."
  value       = { for key, assignment in azurerm_resource_group_policy_assignment.this : key => assignment.id }
}
