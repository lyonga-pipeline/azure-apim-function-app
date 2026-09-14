# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_consumption_budget_resource_group.this
  to   = azurerm_consumption_budget_resource_group.resource_group_budget
}

moved {
  from = azurerm_consumption_budget_subscription.this
  to   = azurerm_consumption_budget_subscription.subscription_budget
}

moved {
  from = azurerm_consumption_budget_management_group.this
  to   = azurerm_consumption_budget_management_group.management_group_budget
}
