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
  value       = { for key, assignment in azurerm_management_group_policy_assignment.mg_assignment : key => assignment.id }
}

output "management_group_assignment_principal_ids" {
  description = "SystemAssigned/UserAssigned principal IDs of management-group assignments that declared an identity, keyed by input key (null where no identity was set)."
  value       = { for key, assignment in azurerm_management_group_policy_assignment.mg_assignment : key => try(assignment.identity[0].principal_id, null) }
}

output "subscription_assignment_ids" {
  description = "Subscription policy assignment IDs keyed by input key."
  value       = { for key, assignment in azurerm_subscription_policy_assignment.subscription_assignment : key => assignment.id }
}

output "subscription_assignment_principal_ids" {
  description = "SystemAssigned/UserAssigned principal IDs of subscription assignments that declared an identity, keyed by input key (null where no identity was set)."
  value       = { for key, assignment in azurerm_subscription_policy_assignment.subscription_assignment : key => try(assignment.identity[0].principal_id, null) }
}

output "resource_group_assignment_ids" {
  description = "Resource group policy assignment IDs keyed by input key."
  value       = { for key, assignment in azurerm_resource_group_policy_assignment.rg_assignment : key => assignment.id }
}

output "resource_group_assignment_principal_ids" {
  description = "SystemAssigned/UserAssigned principal IDs of resource-group assignments that declared an identity, keyed by input key (null where no identity was set)."
  value       = { for key, assignment in azurerm_resource_group_policy_assignment.rg_assignment : key => try(assignment.identity[0].principal_id, null) }
}

output "management_group_exemption_ids" {
  description = "Management-group-scope policy exemption IDs keyed by input key."
  value       = { for key, exemption in azurerm_management_group_policy_exemption.mg_exemption : key => exemption.id }
}

output "subscription_exemption_ids" {
  description = "Subscription-scope policy exemption IDs keyed by input key."
  value       = { for key, exemption in azurerm_subscription_policy_exemption.subscription_exemption : key => exemption.id }
}

output "resource_group_exemption_ids" {
  description = "Resource-group-scope policy exemption IDs keyed by input key."
  value       = { for key, exemption in azurerm_resource_group_policy_exemption.rg_exemption : key => exemption.id }
}

output "policy_exemption_ids" {
  description = "All policy exemption IDs across all 3 scopes, merged into one map keyed by input key."
  value = merge(
    { for key, exemption in azurerm_management_group_policy_exemption.mg_exemption : key => exemption.id },
    { for key, exemption in azurerm_subscription_policy_exemption.subscription_exemption : key => exemption.id },
    { for key, exemption in azurerm_resource_group_policy_exemption.rg_exemption : key => exemption.id },
  )
}
