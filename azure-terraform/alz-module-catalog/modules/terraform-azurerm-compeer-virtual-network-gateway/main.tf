resource "azurerm_virtual_network_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = var.type
  vpn_type            = var.vpn_type
  sku                 = var.sku
  active_active       = var.active_active
  enable_bgp          = var.enable_bgp
  generation          = var.generation
  tags                = var.tags

  dynamic "ip_configuration" {
    for_each = var.ip_configurations
    content {
      name                          = ip_configuration.key
      public_ip_address_id          = ip_configuration.value.public_ip_address_id
      private_ip_address_allocation = try(ip_configuration.value.private_ip_address_allocation, "Dynamic")
      subnet_id                     = ip_configuration.value.subnet_id
    }
  }
}
