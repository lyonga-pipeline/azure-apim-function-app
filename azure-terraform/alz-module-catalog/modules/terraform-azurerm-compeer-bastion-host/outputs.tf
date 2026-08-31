output "id" { value = azurerm_bastion_host.this.id }
output "name" { value = azurerm_bastion_host.this.name }
output "public_ip_id" { value = var.public_ip_id }
output "dns_name" { value = azurerm_bastion_host.this.dns_name }
output "virtual_network_id" { value = azurerm_bastion_host.this.virtual_network_id }
