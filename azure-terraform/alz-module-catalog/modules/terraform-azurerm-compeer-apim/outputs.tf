output "id" {
  description = "Resource ID of the API Management service."
  value       = azurerm_api_management.apim.id
}

output "name" {
  description = "Name of the API Management service."
  value       = azurerm_api_management.apim.name
}

output "gateway_url" {
  description = "Gateway URL of the service."
  value       = azurerm_api_management.apim.gateway_url
}

output "developer_portal_url" {
  description = "Developer portal URL."
  value       = azurerm_api_management.apim.developer_portal_url
}

output "management_api_url" {
  description = "Management API URL."
  value       = azurerm_api_management.apim.management_api_url
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned identity, when enabled."
  value       = try(azurerm_api_management.apim.identity[0].principal_id, null)
}

output "private_ip_addresses" {
  description = "Private IPs of the service (Internal VNet mode)."
  value       = azurerm_api_management.apim.private_ip_addresses
}

output "public_ip_addresses" {
  description = "Public IPs of the service."
  value       = azurerm_api_management.apim.public_ip_addresses
}
