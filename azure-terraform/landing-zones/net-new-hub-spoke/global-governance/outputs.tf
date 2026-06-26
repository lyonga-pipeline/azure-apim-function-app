output "management_group_ids" {
  value = merge(
    { for key, value in azurerm_management_group.root : key => value.id },
    { for key, value in azurerm_management_group.child : key => value.id }
  )
}

output "subscription_placement_ids" {
  value = { for key, value in azurerm_management_group_subscription_association.this : key => value.id }
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
