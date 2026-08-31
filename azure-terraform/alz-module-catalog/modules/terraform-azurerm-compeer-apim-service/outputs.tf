output "id" {
  description = "The API Management service resource ID."
  value       = azurerm_api_management.this.id
}

output "name" {
  description = "The API Management service name."
  value       = azurerm_api_management.this.name
}

output "gateway_url" {
  description = "Public URL of the API gateway."
  value       = azurerm_api_management.this.gateway_url
}

output "gateway_regional_url" {
  description = "Regional URL of the API gateway."
  value       = azurerm_api_management.this.gateway_regional_url
}

output "management_api_url" {
  description = "URL of the management API endpoint."
  value       = azurerm_api_management.this.management_api_url
}

output "developer_portal_url" {
  description = "URL of the developer portal."
  value       = azurerm_api_management.this.developer_portal_url
}

output "portal_url" {
  description = "URL of the (legacy) publisher portal."
  value       = azurerm_api_management.this.portal_url
}

output "public_ip_addresses" {
  description = "Public IP addresses of the service."
  value       = azurerm_api_management.this.public_ip_addresses
}

output "private_ip_addresses" {
  description = "Private IP addresses of the service when VNet-integrated."
  value       = azurerm_api_management.this.private_ip_addresses
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity, when enabled."
  value       = try(azurerm_api_management.this.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "Tenant ID of the managed identity, when enabled."
  value       = try(azurerm_api_management.this.identity[0].tenant_id, null)
}
