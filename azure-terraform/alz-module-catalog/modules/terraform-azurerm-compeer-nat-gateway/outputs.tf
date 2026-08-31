output "id" {
  description = "Resource ID of the NAT gateway."
  value       = azurerm_nat_gateway.nat-gateway.id
}

output "name" {
  description = "Name of the NAT gateway."
  value       = azurerm_nat_gateway.nat-gateway.name
}

output "resource_group_name" {
  description = "Resource group containing the NAT gateway."
  value       = azurerm_nat_gateway.nat-gateway.resource_group_name
}
