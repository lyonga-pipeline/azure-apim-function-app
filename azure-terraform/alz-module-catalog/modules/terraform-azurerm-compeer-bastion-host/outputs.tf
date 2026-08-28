output "id" {
  value = azurerm_bastion_host.this.id
}

output "name" {
  value = azurerm_bastion_host.this.name
}

output "public_ip_id" {
  value = local.public_ip_id
}

output "public_ip_address" {
  value = try(azurerm_public_ip.this[0].ip_address, null)
}

output "dns_name" {
  value = azurerm_bastion_host.this.dns_name
}

output "virtual_network_id" {
  value = azurerm_bastion_host.this.virtual_network_id
}
