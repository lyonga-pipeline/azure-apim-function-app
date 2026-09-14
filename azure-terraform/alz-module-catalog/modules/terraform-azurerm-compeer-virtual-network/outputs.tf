output "id" {
  description = "Resource ID of the virtual network."
  value       = azurerm_virtual_network.network.id
}
output "name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.network.name
}
# NOTE: no `resource_group_name` output. This module consumes the RG name as an
# input; it does not own the resource group. The RG identity is published by the
# resource-group module, and the connectivity/spoke composition layer assembles
# the consumer-facing network bundle (RG name + VNet id/name + subnet_ids).
output "location" {
  description = "Azure region of the virtual network."
  value       = azurerm_virtual_network.network.location
}
output "guid" {
  description = "Immutable GUID of the virtual network."
  value       = azurerm_virtual_network.network.guid
}
output "address_space" {
  description = "Address space (CIDR list) of the virtual network."
  value       = azurerm_virtual_network.network.address_space
}
output "dns_servers" {
  description = "Custom DNS servers configured on the virtual network (empty means Azure-provided DNS)."
  value       = azurerm_virtual_network.network.dns_servers
}
output "subnet_ids" {
  description = "Map of caller-supplied subnet key to subnet resource ID. Consumers reference subnets by key, never by hardcoded name or ID."
  value       = { for key, value in azurerm_subnet.subnet : key => value.id }
}
output "subnet_names" {
  description = "Map of caller-supplied subnet key to Azure subnet name."
  value       = { for key, value in azurerm_subnet.subnet : key => value.name }
}
output "subnets" {
  description = "Map of caller-supplied subnet key to subnet attributes (id, name, address_prefixes, virtual_network_name)."
  value = {
    for key, value in azurerm_subnet.subnet : key => {
      id                   = value.id
      name                 = value.name
      address_prefixes     = value.address_prefixes
      virtual_network_name = value.virtual_network_name
    }
  }
}
