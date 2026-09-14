# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_route_server.this
  to   = azurerm_route_server.server
}

moved {
  from = azurerm_route_server_bgp_connection.this
  to   = azurerm_route_server_bgp_connection.bgp_connection
}
