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
  from = azurerm_resource_group_policy_assignment.this
  to   = azurerm_resource_group_policy_assignment.rg_assignment
}

moved {
  from = azurerm_management_group_policy_exemption.this
  to   = azurerm_management_group_policy_exemption.mg_exemption
}

moved {
  from = azurerm_subscription_policy_exemption.this
  to   = azurerm_subscription_policy_exemption.subscription_exemption
}

moved {
  from = azurerm_resource_group_policy_exemption.this
  to   = azurerm_resource_group_policy_exemption.rg_exemption
}
