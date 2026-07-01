output "id" { value = azurerm_private_dns_resolver.this.id }
output "inbound_endpoint_ids" {
  value = { for key, value in azurerm_private_dns_resolver_inbound_endpoint.this : key => value.id }
}
output "outbound_endpoint_ids" {
  value = { for key, value in azurerm_private_dns_resolver_outbound_endpoint.this : key => value.id }
}
output "forwarding_ruleset_ids" {
  value = { for key, value in azurerm_private_dns_resolver_dns_forwarding_ruleset.this : key => value.id }
}
