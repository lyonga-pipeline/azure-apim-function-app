output "private_endpoint_id" {
  description = "The ID of the Private Endpoint."
  value       = azurerm_private_endpoint.private_endpoint.id
}

output "id" {
  description = "The ID of the Private Endpoint."
  value       = azurerm_private_endpoint.private_endpoint.id
}

output "private_endpoint_name" {
  description = "The name of the Private Endpoint."
  value       = azurerm_private_endpoint.private_endpoint.name
}

output "name" {
  description = "The name of the Private Endpoint."
  value       = azurerm_private_endpoint.private_endpoint.name
}

output "resource_group_name" {
  description = "The resource group containing the Private Endpoint."
  value       = azurerm_private_endpoint.private_endpoint.resource_group_name
}

output "location" {
  description = "The Azure region of the Private Endpoint."
  value       = azurerm_private_endpoint.private_endpoint.location
}

output "subnet_id" {
  description = "The subnet ID used by the Private Endpoint."
  value       = azurerm_private_endpoint.private_endpoint.subnet_id
}

output "network_interface_ids" {
  description = "Network interface IDs created for the Private Endpoint."
  value       = [for nic in azurerm_private_endpoint.private_endpoint.network_interface : nic.id]
}

output "network_interfaces" {
  description = "Network interfaces created for the Private Endpoint."
  value       = azurerm_private_endpoint.private_endpoint.network_interface
}

output "private_service_connection" {
  description = "Private service connection details."
  value       = azurerm_private_endpoint.private_endpoint.private_service_connection
}

output "custom_dns_configs" {
  description = "Custom DNS configurations discovered for the Private Endpoint."
  value       = azurerm_private_endpoint.private_endpoint.custom_dns_configs
}

output "private_dns_zone_configs" {
  description = "Private DNS zone configuration details."
  value       = azurerm_private_endpoint.private_endpoint.private_dns_zone_configs
}
