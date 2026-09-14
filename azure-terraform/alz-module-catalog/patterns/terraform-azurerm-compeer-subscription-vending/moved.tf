# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_subscription.this
  to   = azurerm_subscription.subscription
}

moved {
  from = azurerm_management_group_subscription_association.this
  to   = azurerm_management_group_subscription_association.association
}
