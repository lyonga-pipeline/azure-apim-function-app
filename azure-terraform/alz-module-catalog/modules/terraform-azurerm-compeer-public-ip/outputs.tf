output "id" {
  description = "Resource ID of the public IP address."
  value       = azurerm_public_ip.ip.id
}

output "name" {
  description = "Name of the public IP address."
  value       = azurerm_public_ip.ip.name
}

output "resource_group_name" {
  description = "Name of the resource group containing the public IP."
  value       = azurerm_public_ip.ip.resource_group_name
}

output "location" {
  description = "Azure region of the public IP."
  value       = azurerm_public_ip.ip.location
}

output "ip_address" {
  description = "Allocated IP address (empty until associated for Dynamic allocation)."
  value       = azurerm_public_ip.ip.ip_address
}

output "fqdn" {
  description = "Fully qualified domain name assigned to the public IP, when a domain name label is set."
  value       = azurerm_public_ip.ip.fqdn
}

output "zones" {
  description = "Availability zones the public IP is pinned to."
  value       = azurerm_public_ip.ip.zones
}
