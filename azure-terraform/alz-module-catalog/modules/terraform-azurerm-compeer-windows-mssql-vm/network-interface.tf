resource "azurerm_network_interface" "nic" {
  name                           = var.nic_name
  resource_group_name            = var.resource_group_name
  location                       = var.location
  dns_servers                    = var.dns_servers
  // enable_ip_forwarding          = var.enable_ip_forwarding
  // enable_accelerated_networking = var.enable_accelerated_networking
  ip_forwarding_enabled          = var.ip_forwarding_enabled
  accelerated_networking_enabled = var.accelerated_networking_enabled
  internal_dns_name_label        = var.internal_dns_name_label

  ip_configuration {
    name                          = var.ip_configuration_name
    primary                       = true
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation_type
    private_ip_address            = var.private_ip_address_allocation_type == "Static" ? element(concat(var.private_ip_address, [""]), 0) : null
  }
}