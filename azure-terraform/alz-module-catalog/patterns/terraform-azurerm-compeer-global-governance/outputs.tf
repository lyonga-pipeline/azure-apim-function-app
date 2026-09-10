output "management_group_ids" {
  description = "Management group resource IDs keyed by management group key (from the management-groups module)."
  value       = module.management_groups.management_group_ids
}

output "subscription_placement_ids" {
  description = "Management group subscription association IDs keyed `<management_group_key>-<subscription_id>`."
  value       = module.management_groups.subscription_association_ids
}

output "custom_policy_definition_ids" {
  value = { for key, value in azurerm_policy_definition.this : key => value.id }
}

output "custom_policy_set_definition_ids" {
  value = { for key, value in azurerm_policy_set_definition.this : key => value.id }
}

output "management_group_policy_assignment_ids" {
  value = { for key, value in azurerm_management_group_policy_assignment.this : key => value.id }
}

output "subscription_policy_assignment_ids" {
  value = { for key, value in azurerm_subscription_policy_assignment.this : key => value.id }
}

output "custom_role_definition_ids" {
  value = { for key, value in module.custom_role_definitions : key => value.id }
}

output "role_assignment_ids" {
  value = module.role_assignments.ids
}

output "management_group_budget_ids" {
  value = { for key, value in azurerm_consumption_budget_management_group.this : key => value.id }
}
