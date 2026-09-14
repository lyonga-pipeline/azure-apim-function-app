# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_private_dns_zone.this
  to   = azurerm_private_dns_zone.zone
}

moved {
  from = azurerm_private_dns_zone_virtual_network_link.this
  to   = azurerm_private_dns_zone_virtual_network_link.vnet_link
}
