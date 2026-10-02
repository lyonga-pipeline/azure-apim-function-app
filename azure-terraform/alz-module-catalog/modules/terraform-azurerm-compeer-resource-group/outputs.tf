output "group_ids" {
  description = "Resource group IDs keyed by the stable resource_groups input key."
  value       = { for key, group in azurerm_resource_group.groups : key => group.id }
}

output "group_names" {
  description = "Resource group names keyed by the stable resource_groups input key."
  value       = { for key, group in azurerm_resource_group.groups : key => group.name }
}

output "group_locations" {
  description = "Resource group locations keyed by the stable resource_groups input key."
  value       = { for key, group in azurerm_resource_group.groups : key => group.location }
}

output "id" {
  description = "Compatibility output for the resource group keyed as main."
  value       = try(azurerm_resource_group.groups["main"].id, null)
}

output "name" {
  description = "Compatibility output for the resource group keyed as main."
  value       = try(azurerm_resource_group.groups["main"].name, null)
}

output "location" {
  description = "Compatibility output for the resource group keyed as main."
  value       = try(azurerm_resource_group.groups["main"].location, null)
}
