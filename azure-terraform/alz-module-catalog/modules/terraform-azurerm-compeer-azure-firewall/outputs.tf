output "id" {
  description = "Resource ID of the Azure Firewall."
  value       = azurerm_firewall.firewall.id
}
output "name" {
  description = "Name of the Azure Firewall."
  value       = azurerm_firewall.firewall.name
}
output "private_ip_address" {
  description = "Private IP address of the firewall's first IP configuration (null if none), used as the next hop for route tables."
  value       = try(azurerm_firewall.firewall.ip_configuration[0].private_ip_address, null)
}
