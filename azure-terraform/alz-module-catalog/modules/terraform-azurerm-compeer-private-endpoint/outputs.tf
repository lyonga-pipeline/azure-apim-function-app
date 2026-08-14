output "private_endpoint_id" {
  description = "The ID of the Private Endpoint."
  value       = azurerm_private_endpoint.private_endpoint.id
}

output "private_endpoint_name" {
  description = "The name of the Private Endpoint."
  value       = azurerm_private_endpoint.private_endpoint.name
}
