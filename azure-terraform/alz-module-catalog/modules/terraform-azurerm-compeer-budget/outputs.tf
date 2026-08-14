output "budget_id" {
  description = "Created budget resource ID."
  value = try(
    azurerm_consumption_budget_resource_group.this[0].id,
    azurerm_consumption_budget_subscription.this[0].id,
    azurerm_consumption_budget_management_group.this[0].id,
    null
  )
}

output "budget_scope_type" {
  description = "Resolved budget scope type."
  value       = local.budget_scope_type
}

output "rg_budget_id" {
  description = "Resource group budget ID when scope_type is resource_group."
  value       = try(azurerm_consumption_budget_resource_group.this[0].id, null)
}

output "subscription_budget_id" {
  description = "Subscription budget ID when scope_type is subscription."
  value       = try(azurerm_consumption_budget_subscription.this[0].id, null)
}

output "management_group_budget_id" {
  description = "Management group budget ID when scope_type is management_group."
  value       = try(azurerm_consumption_budget_management_group.this[0].id, null)
}
