output "id" {
  description = "Resource ID of the route table."
  value       = azurerm_route_table.rt.id
}

output "name" {
  description = "Name of the route table."
  value       = azurerm_route_table.rt.name
}

output "resource_group_name" {
  description = "Resource group containing the route table."
  value       = azurerm_route_table.rt.resource_group_name
}

output "location" {
  description = "Azure region of the route table."
  value       = azurerm_route_table.rt.location
}

output "subnet_ids" {
  description = "Subnet IDs currently associated with this route table (managed externally)."
  value       = azurerm_route_table.rt.subnets
}
