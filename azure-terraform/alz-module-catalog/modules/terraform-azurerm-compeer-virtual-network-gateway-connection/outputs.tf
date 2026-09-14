output "id" {
  description = "Resource ID of the virtual network gateway connection."
  value       = azurerm_virtual_network_gateway_connection.connection.id
}
output "name" {
  description = "Name of the virtual network gateway connection."
  value       = azurerm_virtual_network_gateway_connection.connection.name
}
output "type" {
  description = "Connection type (IPsec, Vnet2Vnet, or ExpressRoute)."
  value       = azurerm_virtual_network_gateway_connection.connection.type
}
output "resource_group_name" {
  description = "Name of the resource group containing the connection."
  value       = azurerm_virtual_network_gateway_connection.connection.resource_group_name
}
output "location" {
  description = "Azure region of the connection."
  value       = azurerm_virtual_network_gateway_connection.connection.location
}
