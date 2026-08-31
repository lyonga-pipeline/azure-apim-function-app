output "id" {
  description = "Resource ID of the App Service Environment v3."
  value       = azurerm_app_service_environment_v3.this.id
}

output "name" {
  description = "Name of the App Service Environment v3."
  value       = azurerm_app_service_environment_v3.this.name
}

output "dns_suffix" {
  description = "DNS suffix of the ASE, used to build app hostnames."
  value       = azurerm_app_service_environment_v3.this.dns_suffix
}

output "internal_inbound_ip_addresses" {
  description = "Internal inbound IP addresses of the ASE."
  value       = azurerm_app_service_environment_v3.this.internal_inbound_ip_addresses
}

output "external_inbound_ip_addresses" {
  description = "External inbound IP addresses of the ASE."
  value       = azurerm_app_service_environment_v3.this.external_inbound_ip_addresses
}
