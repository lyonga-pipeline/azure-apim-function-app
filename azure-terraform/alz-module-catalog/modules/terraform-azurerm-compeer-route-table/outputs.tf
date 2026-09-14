output "id" {
  description = "Resource ID of the route table."
  value       = azurerm_route_table.table.id
}

output "name" {
  description = "Name of the route table."
  value       = azurerm_route_table.table.name
}

output "resource_group_name" {
  description = "Resource group containing the route table."
  value       = azurerm_route_table.table.resource_group_name
}

output "subnet_ids" {
  description = "Subnet IDs currently associated (managed externally)."
  value       = azurerm_route_table.table.subnets
}
