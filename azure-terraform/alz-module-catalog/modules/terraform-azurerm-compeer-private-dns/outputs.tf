output "private_dns_zone_id" {
  description = "The Private DNS Zone ID."
  value       = azurerm_private_dns_zone.private_dns_zone.id
}

output "private_dns_zone_name" {
  description = "The Private DNS Zone name."
  value       = azurerm_private_dns_zone.private_dns_zone.name
}

output "private_dns_zone_virtual_network_link" {
  description = "The ID of the Private DNS Zone Virtual Network Link."
  value       = azurerm_private_dns_zone_virtual_network_link.private_dns_zone_virtual_network_link.id
}
