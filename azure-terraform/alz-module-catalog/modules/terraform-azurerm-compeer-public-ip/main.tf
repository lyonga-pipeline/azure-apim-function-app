resource "azurerm_public_ip" "this" {
  name                    = var.name
  resource_group_name     = var.resource_group_name
  location                = var.location
  allocation_method       = var.allocation_method
  sku                     = var.sku
  sku_tier                = var.sku_tier
  ip_version              = var.ip_version
  edge_zone               = var.edge_zone
  domain_name_label       = var.domain_name_label
  domain_name_label_scope = var.domain_name_label_scope
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  public_ip_prefix_id     = var.public_ip_prefix_id
  reverse_fqdn            = var.reverse_fqdn
  ddos_protection_mode    = var.ddos_protection_mode
  ddos_protection_plan_id = var.ddos_protection_plan_id
  ip_tags                 = var.ip_tags
  zones                   = var.zones
  tags                    = var.tags

  lifecycle {
    precondition {
      condition     = var.sku != "Standard" || var.allocation_method == "Static"
      error_message = "Standard SKU public IPs must use Static allocation."
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}
