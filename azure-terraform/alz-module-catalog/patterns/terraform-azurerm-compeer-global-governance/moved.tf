# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_policy_definition.this
  to   = azurerm_policy_definition.definition
}

moved {
  from = azurerm_policy_set_definition.this
  to   = azurerm_policy_set_definition.initiative
}

moved {
  from = azurerm_management_group_policy_assignment.this
  to   = azurerm_management_group_policy_assignment.mg_assignment
}

moved {
  from = azurerm_subscription_policy_assignment.this
  to   = azurerm_subscription_policy_assignment.subscription_assignment
}

moved {
  from = azurerm_consumption_budget_management_group.this
  to   = azurerm_consumption_budget_management_group.management_group_budget
}
