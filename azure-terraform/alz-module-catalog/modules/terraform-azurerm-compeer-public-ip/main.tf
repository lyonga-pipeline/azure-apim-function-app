resource "azurerm_public_ip" "this" {
  name                    = var.name
  resource_group_name     = var.resource_group_name
  location                = var.location
  allocation_method       = var.allocation_method
  sku                     = var.sku
  sku_tier                = var.sku_tier
  ip_version              = var.ip_version
  domain_name_label       = var.domain_name_label
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  public_ip_prefix_id     = var.public_ip_prefix_id
  reverse_fqdn            = var.reverse_fqdn
  zones                   = var.zones
  tags                    = var.tags
}
