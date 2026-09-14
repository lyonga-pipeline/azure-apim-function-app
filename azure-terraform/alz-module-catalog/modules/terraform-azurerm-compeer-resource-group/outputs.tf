output "id" {
  description = "Resource ID of the resource group."
  value       = azurerm_resource_group.group.id
}

output "name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.group.name
}

output "location" {
  description = "Azure region of the resource group."
  value       = azurerm_resource_group.group.location
}
