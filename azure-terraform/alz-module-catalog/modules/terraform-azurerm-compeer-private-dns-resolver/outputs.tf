output "id" { value = azurerm_private_dns_resolver.this.id }
output "name" { value = azurerm_private_dns_resolver.this.name }
output "resource_group_name" { value = azurerm_private_dns_resolver.this.resource_group_name }
output "location" { value = azurerm_private_dns_resolver.this.location }
output "virtual_network_id" { value = azurerm_private_dns_resolver.this.virtual_network_id }
output "inbound_endpoint_ids" {
  value = { for key, value in azurerm_private_dns_resolver_inbound_endpoint.this : key => value.id }
}
output "inbound_endpoints" {
  value = {
    for key, value in azurerm_private_dns_resolver_inbound_endpoint.this : key => {
      id                = value.id
      name              = value.name
      ip_configurations = value.ip_configurations
    }
  }
}
output "outbound_endpoint_ids" {
  value = { for key, value in azurerm_private_dns_resolver_outbound_endpoint.this : key => value.id }
}
output "outbound_endpoints" {
  value = {
    for key, value in azurerm_private_dns_resolver_outbound_endpoint.this : key => {
      id        = value.id
      name      = value.name
      subnet_id = value.subnet_id
    }
  }
}
output "forwarding_ruleset_ids" {
  value = { for key, value in azurerm_private_dns_resolver_dns_forwarding_ruleset.this : key => value.id }
}
output "forwarding_rule_ids" {
  value = { for key, value in azurerm_private_dns_resolver_forwarding_rule.this : key => value.id }
}
output "forwarding_ruleset_vnet_link_ids" {
  value = { for key, value in azurerm_private_dns_resolver_virtual_network_link.this : key => value.id }
}
