# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_lb.this
  to   = azurerm_lb.load_balancer
}

moved {
  from = azurerm_lb_backend_address_pool.this
  to   = azurerm_lb_backend_address_pool.backend_pool
}

moved {
  from = azurerm_lb_backend_address_pool_address.this
  to   = azurerm_lb_backend_address_pool_address.backend_pool_address
}

moved {
  from = azurerm_lb_probe.this
  to   = azurerm_lb_probe.probe
}

moved {
  from = azurerm_lb_rule.this
  to   = azurerm_lb_rule.rule
}

moved {
  from = azurerm_lb_nat_rule.this
  to   = azurerm_lb_nat_rule.nat_rule
}

moved {
  from = azurerm_lb_outbound_rule.this
  to   = azurerm_lb_outbound_rule.outbound_rule
}
