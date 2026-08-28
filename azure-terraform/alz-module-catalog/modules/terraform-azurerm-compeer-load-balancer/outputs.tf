output "id" { value = azurerm_lb.this.id }
output "name" { value = azurerm_lb.this.name }
output "resource_group_name" { value = azurerm_lb.this.resource_group_name }
output "location" { value = azurerm_lb.this.location }

output "frontend_ip_configurations" {
  value = azurerm_lb.this.frontend_ip_configuration
}

output "backend_pool_ids" {
  value = { for key, value in azurerm_lb_backend_address_pool.this : key => value.id }
}

output "backend_address_ids" {
  value = { for key, value in azurerm_lb_backend_address_pool_address.this : key => value.id }
}

output "probe_ids" {
  value = { for key, value in azurerm_lb_probe.this : key => value.id }
}

output "rule_ids" {
  value = { for key, value in azurerm_lb_rule.this : key => value.id }
}

output "nat_rule_ids" {
  value = { for key, value in azurerm_lb_nat_rule.this : key => value.id }
}

output "outbound_rule_ids" {
  value = { for key, value in azurerm_lb_outbound_rule.this : key => value.id }
}
