# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_virtual_network.this
  to   = azurerm_virtual_network.network
}

moved {
  from = azurerm_subnet.this
  to   = azurerm_subnet.subnet
}
