output "id" {
  description = "Resource ID of the virtual network."
  value       = azurerm_virtual_network.vnet.id
}

output "name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.vnet.name
}

output "resource_group_name" {
  description = "Resource group containing the virtual network."
  value       = azurerm_virtual_network.vnet.resource_group_name
}

output "location" {
  description = "Azure region of the virtual network."
  value       = azurerm_virtual_network.vnet.location
}

output "address_space" {
  description = "Address space assigned to the virtual network."
  value       = azurerm_virtual_network.vnet.address_space
}

output "guid" {
  description = "GUID of the virtual network."
  value       = azurerm_virtual_network.vnet.guid
}

output "subnet_ids" {
  description = "Map of subnet name => subnet resource ID."
  value       = { for k, s in azurerm_subnet.subnet : k => s.id }
}

output "subnet_names" {
  description = "Map of subnet key => Azure subnet name."
  value       = { for k, s in azurerm_subnet.subnet : k => s.name }
}

output "subnets" {
  description = "Map of subnet name => { id, name, address_prefixes } for downstream composition."
  value = {
    for k, s in azurerm_subnet.subnet : k => {
      id               = s.id
      name             = s.name
      address_prefixes = s.address_prefixes
    }
  }
}
