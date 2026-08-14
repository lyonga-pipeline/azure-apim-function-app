resource "azurerm_network_interface" "this" {
  name                           = var.name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  dns_servers                    = var.dns_servers
  accelerated_networking_enabled = var.accelerated_networking_enabled
  ip_forwarding_enabled          = var.ip_forwarding_enabled
  tags                           = var.tags

  dynamic "ip_configuration" {
    for_each = var.ip_configurations
    content {
      name                                               = ip_configuration.key
      subnet_id                                          = ip_configuration.value.subnet_id
      private_ip_address_allocation                      = ip_configuration.value.private_ip_address_allocation
      private_ip_address                                 = try(ip_configuration.value.private_ip_address, null)
      primary                                            = try(ip_configuration.value.primary, null)
      public_ip_address_id                               = try(ip_configuration.value.public_ip_address_id, null)
      gateway_load_balancer_frontend_ip_configuration_id = try(ip_configuration.value.gateway_load_balancer_frontend_ip_configuration_id, null)
    }
  }
}
