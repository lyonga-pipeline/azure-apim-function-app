resource "azurerm_firewall" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = var.sku_name
  sku_tier            = var.sku_tier
  firewall_policy_id  = var.firewall_policy_id
  zones               = var.zones
  tags                = var.tags

  dynamic "ip_configuration" {
    for_each = var.ip_configurations
    content {
      name                 = ip_configuration.key
      subnet_id            = try(ip_configuration.value.subnet_id, null)
      public_ip_address_id = ip_configuration.value.public_ip_address_id
    }
  }
}
