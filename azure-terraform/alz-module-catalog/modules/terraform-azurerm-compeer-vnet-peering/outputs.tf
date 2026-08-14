output "peering_id" {
  description = "The ID of the virtual network peering."
  value       = azurerm_virtual_network_peering.peering.id
}

output "peering_name" {
  description = "The name of the virtual network peering."
  value       = azurerm_virtual_network_peering.peering.name
}

output "peering_resource_group_name" {
  description = "The resource group where the virtual network peering is defined."
  value       = azurerm_virtual_network_peering.peering.resource_group_name
}

output "peering_virtual_network_name" {
  description = "The name of the virtual network that is being peered."
  value       = azurerm_virtual_network_peering.peering.virtual_network_name
}

output "peering_remote_virtual_network_id" {
  description = "The ID of the remote virtual network that is being peered."
  value       = azurerm_virtual_network_peering.peering.remote_virtual_network_id
}

output "peering_allow_virtual_network_access" {
  description = "Whether the virtual network access is allowed."
  value       = azurerm_virtual_network_peering.peering.allow_virtual_network_access
}

output "peering_allow_forwarded_traffic" {
  description = "Whether the forwarded traffic is allowed."
  value       = azurerm_virtual_network_peering.peering.allow_forwarded_traffic
}

output "peering_allow_gateway_transit" {
  description = "Whether gateway transit is allowed."
  value       = azurerm_virtual_network_peering.peering.allow_gateway_transit
}

output "peering_use_remote_gateways" {
  description = "Whether remote gateways are used."
  value       = azurerm_virtual_network_peering.peering.use_remote_gateways
}
