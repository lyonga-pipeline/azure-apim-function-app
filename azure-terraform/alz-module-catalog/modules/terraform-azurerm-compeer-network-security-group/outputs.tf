output "network_security_group_id" {
  description = "The ID of the Network Security Group."
  value       = azurerm_network_security_group.network_security_group.id
}

output "id" {
  description = "The ID of the Network Security Group."
  value       = azurerm_network_security_group.network_security_group.id
}

output "name" {
  description = "The name of the Network Security Group."
  value       = azurerm_network_security_group.network_security_group.name
}

output "resource_group_name" {
  description = "The resource group containing the Network Security Group."
  value       = azurerm_network_security_group.network_security_group.resource_group_name
}

output "network_security_group_rules" {
  description = "A list of security rules applied to the Network Security Group."
  value       = azurerm_network_security_group.network_security_group.security_rule
}
