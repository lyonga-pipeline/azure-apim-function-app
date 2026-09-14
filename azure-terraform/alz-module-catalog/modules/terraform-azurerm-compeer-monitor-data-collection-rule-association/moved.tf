# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_monitor_data_collection_rule_association.this
  to   = azurerm_monitor_data_collection_rule_association.association
}
