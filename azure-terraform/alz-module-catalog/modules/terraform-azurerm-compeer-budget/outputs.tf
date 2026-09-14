output "budget_id" {
  description = "Created budget resource ID."
  value = try(
    azurerm_consumption_budget_resource_group.resource_group_budget[0].id,
    azurerm_consumption_budget_subscription.subscription_budget[0].id,
    azurerm_consumption_budget_management_group.management_group_budget[0].id,
    null
  )
}

output "budget_scope_type" {
  description = "Resolved budget scope type."
  value       = local.budget_scope_type
}

output "rg_budget_id" {
  description = "Resource group budget ID when scope_type is resource_group."
  value       = try(azurerm_consumption_budget_resource_group.resource_group_budget[0].id, null)
}

output "subscription_budget_id" {
  description = "Subscription budget ID when scope_type is subscription."
  value       = try(azurerm_consumption_budget_subscription.subscription_budget[0].id, null)
}

output "management_group_budget_id" {
  description = "Management group budget ID when scope_type is management_group."
  value       = try(azurerm_consumption_budget_management_group.management_group_budget[0].id, null)
}

output "id" {
  description = "Resource ID of the created budget, whichever scope. Stable alias for budget_id."
  value       = try(azurerm_consumption_budget_resource_group.resource_group_budget[0].id, azurerm_consumption_budget_subscription.subscription_budget[0].id, azurerm_consumption_budget_management_group.management_group_budget[0].id, null)
}
