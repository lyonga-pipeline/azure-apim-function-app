output "id" { value = azurerm_network_interface.this.id }
output "ip_configuration_ids" {
  value = azurerm_network_interface.this.ip_configuration[*].id
}
output "name" { value = azurerm_network_interface.this.name }
output "resource_group_name" { value = azurerm_network_interface.this.resource_group_name }
output "private_ip_addresses" {
  value = { for cfg in azurerm_network_interface.this.ip_configuration : cfg.name => cfg.private_ip_address }
}
output "ip_configurations" {
  value = {
    for cfg in azurerm_network_interface.this.ip_configuration : cfg.name => {
      id                            = cfg.id
      name                          = cfg.name
      private_ip_address            = cfg.private_ip_address
      private_ip_address_version    = cfg.private_ip_address_version
      private_ip_address_allocation = cfg.private_ip_address_allocation
      public_ip_address_id          = cfg.public_ip_address_id
      subnet_id                     = cfg.subnet_id
      primary                       = cfg.primary
    }
  }
}
