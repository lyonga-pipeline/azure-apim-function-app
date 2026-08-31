output "id" {
  description = "Resource ID of the network interface."
  value       = azurerm_network_interface.this.id
}

output "name" {
  description = "Name of the network interface."
  value       = azurerm_network_interface.this.name
}

output "resource_group_name" {
  description = "Resource group containing the NIC."
  value       = azurerm_network_interface.this.resource_group_name
}

output "mac_address" {
  description = "MAC address assigned to the NIC (known after apply)."
  value       = azurerm_network_interface.this.mac_address
}

output "private_ip_address" {
  description = "Primary private IP address of the NIC."
  value       = azurerm_network_interface.this.private_ip_address
}

output "private_ip_addresses" {
  description = "All private IP addresses on the NIC."
  value       = azurerm_network_interface.this.private_ip_addresses
}

output "ip_configurations" {
  description = "IP configuration attributes keyed by config name."
  value = {
    for cfg in azurerm_network_interface.this.ip_configuration : cfg.name => {
      name                          = cfg.name
      subnet_id                     = cfg.subnet_id
      private_ip_address            = cfg.private_ip_address
      private_ip_address_version    = cfg.private_ip_address_version
      private_ip_address_allocation = cfg.private_ip_address_allocation
      public_ip_address_id          = cfg.public_ip_address_id
      primary                       = cfg.primary
    }
  }
}
