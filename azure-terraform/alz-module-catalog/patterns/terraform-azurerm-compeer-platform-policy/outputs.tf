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

output "resource_group_policy_assignment_ids" {
  value = { for k, v in azurerm_resource_group_policy_assignment.this : k => v.id }
}

output "policy_exemption_ids" {
  value = merge(
    { for k, v in azurerm_management_group_policy_exemption.this : k => v.id },
    { for k, v in azurerm_subscription_policy_exemption.this : k => v.id },
    { for k, v in azurerm_resource_group_policy_exemption.this : k => v.id },
  )
}

output "remediation_assignment_ids" {
  value = { for k, v in azurerm_management_group_policy_assignment.remediation : k => v.id }
}

output "remediation_assignment_principal_ids" {
  description = "SystemAssigned principal IDs of the remediation assignments - grant these the roles their DINE policies require."
  value       = { for k, v in azurerm_management_group_policy_assignment.remediation : k => try(v.identity[0].principal_id, null) }
}
