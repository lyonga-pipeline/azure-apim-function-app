output "id" {
  description = "Resource ID of the private DNS resolver."
  value       = azurerm_private_dns_resolver.this.id
}
output "name" {
  description = "Name of the private DNS resolver."
  value       = azurerm_private_dns_resolver.this.name
}
output "resource_group_name" {
  description = "Name of the resource group containing the private DNS resolver."
  value       = azurerm_private_dns_resolver.this.resource_group_name
}
output "location" {
  description = "Azure region of the private DNS resolver."
  value       = azurerm_private_dns_resolver.this.location
}
output "virtual_network_id" {
  description = "Resource ID of the virtual network the resolver is bound to."
  value       = azurerm_private_dns_resolver.this.virtual_network_id
}
output "inbound_endpoint_ids" {
  description = "Map of caller-supplied key to inbound endpoint resource ID."
  value       = { for key, value in azurerm_private_dns_resolver_inbound_endpoint.this : key => value.id }
}
output "inbound_endpoints" {
  description = "Map of caller-supplied key to inbound endpoint attributes (id, ip_configurations), for forwarder targeting."
  value = {
    for key, value in azurerm_private_dns_resolver_inbound_endpoint.this : key => {
      id                = value.id
      name              = value.name
      ip_configurations = value.ip_configurations
    }
  }
}
output "outbound_endpoint_ids" {
  description = "Map of caller-supplied key to outbound endpoint resource ID."
  value       = { for key, value in azurerm_private_dns_resolver_outbound_endpoint.this : key => value.id }
}
output "outbound_endpoints" {
  description = "Map of caller-supplied key to outbound endpoint attributes (id, subnet_id)."
  value = {
    for key, value in azurerm_private_dns_resolver_outbound_endpoint.this : key => {
      id        = value.id
      name      = value.name
      subnet_id = value.subnet_id
    }
  }
}
output "forwarding_ruleset_ids" {
  description = "Map of caller-supplied key to DNS forwarding ruleset resource ID."
  value       = { for key, value in azurerm_private_dns_resolver_dns_forwarding_ruleset.this : key => value.id }
}
output "forwarding_rule_ids" {
  description = "Map of caller-supplied key to DNS forwarding rule resource ID."
  value       = { for key, value in azurerm_private_dns_resolver_forwarding_rule.this : key => value.id }
}
output "forwarding_ruleset_vnet_link_ids" {
  description = "Map of caller-supplied key to forwarding-ruleset virtual network link resource ID."
  value       = { for key, value in azurerm_private_dns_resolver_virtual_network_link.this : key => value.id }
}
