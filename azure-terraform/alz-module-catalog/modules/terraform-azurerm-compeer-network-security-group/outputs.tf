output "network_security_group_id" {
  description = "The ID of the Network Security Group."
  value       = azurerm_network_security_group.network_security_group.id
}

output "network_security_group_rules" {
  description = "A list of security rules applied to the Network Security Group."
  value       = azurerm_network_security_group.network_security_group.security_rule
}