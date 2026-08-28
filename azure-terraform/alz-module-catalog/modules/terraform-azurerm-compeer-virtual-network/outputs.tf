output "id" { value = azurerm_virtual_network.this.id }
output "name" { value = azurerm_virtual_network.this.name }
output "resource_group_name" { value = azurerm_virtual_network.this.resource_group_name }
output "location" { value = azurerm_virtual_network.this.location }
output "guid" { value = azurerm_virtual_network.this.guid }
output "address_space" { value = azurerm_virtual_network.this.address_space }
output "dns_servers" { value = azurerm_virtual_network.this.dns_servers }
output "subnet_ids" {
  value = { for key, value in azurerm_subnet.this : key => value.id }
}
output "subnet_names" {
  value = { for key, value in azurerm_subnet.this : key => value.name }
}
output "subnets" {
  value = {
    for key, value in azurerm_subnet.this : key => {
      id                   = value.id
      name                 = value.name
      address_prefixes     = value.address_prefixes
      resource_group_name  = value.resource_group_name
      virtual_network_name = value.virtual_network_name
    }
  }
}
