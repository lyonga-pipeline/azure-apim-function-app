# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_private_dns_resolver.this
  to   = azurerm_private_dns_resolver.resolver
}

moved {
  from = azurerm_private_dns_resolver_inbound_endpoint.this
  to   = azurerm_private_dns_resolver_inbound_endpoint.inbound_endpoint
}

moved {
  from = azurerm_private_dns_resolver_outbound_endpoint.this
  to   = azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoint
}

moved {
  from = azurerm_private_dns_resolver_dns_forwarding_ruleset.this
  to   = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset
}

moved {
  from = azurerm_private_dns_resolver_forwarding_rule.this
  to   = azurerm_private_dns_resolver_forwarding_rule.forwarding_rule
}

moved {
  from = azurerm_private_dns_resolver_virtual_network_link.this
  to   = azurerm_private_dns_resolver_virtual_network_link.vnet_link
}
