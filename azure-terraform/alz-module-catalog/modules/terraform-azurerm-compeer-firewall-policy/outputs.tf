output "id" {
  description = "Resource ID of the firewall policy."
  value       = azurerm_firewall_policy.this.id
}
output "name" {
  description = "Name of the firewall policy."
  value       = azurerm_firewall_policy.this.name
}
