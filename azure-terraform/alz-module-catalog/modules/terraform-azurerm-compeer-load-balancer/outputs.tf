output "id" {
  description = "Resource ID of the load balancer."
  value       = azurerm_lb.this.id
}
output "name" {
  description = "Name of the load balancer."
  value       = azurerm_lb.this.name
}
output "resource_group_name" {
  description = "Name of the resource group containing the load balancer."
  value       = azurerm_lb.this.resource_group_name
}
output "location" {
  description = "Azure region of the load balancer."
  value       = azurerm_lb.this.location
}

output "frontend_ip_configurations" {
  description = "Frontend IP configuration blocks of the load balancer (name, private_ip_address, subnet_id, id)."
  value       = azurerm_lb.this.frontend_ip_configuration
}

output "backend_pool_ids" {
  description = "Map of caller-supplied key to backend address pool resource ID."
  value       = { for key, value in azurerm_lb_backend_address_pool.this : key => value.id }
}

output "backend_address_ids" {
  description = "Map of caller-supplied key to backend address pool address resource ID."
  value       = { for key, value in azurerm_lb_backend_address_pool_address.this : key => value.id }
}

output "probe_ids" {
  description = "Map of caller-supplied key to health probe resource ID."
  value       = { for key, value in azurerm_lb_probe.this : key => value.id }
}

output "rule_ids" {
  description = "Map of caller-supplied key to load balancing rule resource ID."
  value       = { for key, value in azurerm_lb_rule.this : key => value.id }
}

output "nat_rule_ids" {
  description = "Map of caller-supplied key to inbound NAT rule resource ID."
  value       = { for key, value in azurerm_lb_nat_rule.this : key => value.id }
}

output "outbound_rule_ids" {
  description = "Map of caller-supplied key to outbound rule resource ID."
  value       = { for key, value in azurerm_lb_outbound_rule.this : key => value.id }
}
