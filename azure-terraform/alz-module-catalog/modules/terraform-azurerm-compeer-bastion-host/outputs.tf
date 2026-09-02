output "id" {
  description = "Resource ID of the Bastion host."
  value       = azurerm_bastion_host.this.id
}
output "name" {
  description = "Name of the Bastion host."
  value       = azurerm_bastion_host.this.name
}
output "public_ip_id" {
  description = "Resource ID of the public IP associated with the Bastion host (passed through from input)."
  value       = var.public_ip_id
}
output "dns_name" {
  description = "FQDN of the Bastion host."
  value       = azurerm_bastion_host.this.dns_name
}
output "virtual_network_id" {
  description = "Resource ID of the virtual network the Bastion host is deployed into."
  value       = azurerm_bastion_host.this.virtual_network_id
}
