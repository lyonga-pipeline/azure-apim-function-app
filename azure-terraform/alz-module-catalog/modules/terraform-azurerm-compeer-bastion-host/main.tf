resource "azurerm_bastion_host" "this" {
  name                      = var.name
  resource_group_name       = var.resource_group_name
  location                  = var.location
  sku                       = var.sku
  copy_paste_enabled        = var.copy_paste_enabled
  file_copy_enabled         = var.file_copy_enabled
  ip_connect_enabled        = var.ip_connect_enabled
  kerberos_enabled          = var.kerberos_enabled
  session_recording_enabled = var.session_recording_enabled
  shareable_link_enabled    = var.shareable_link_enabled
  tunneling_enabled         = var.tunneling_enabled
  scale_units               = var.scale_units
  zones                     = var.zones
  tags                      = var.tags

  ip_configuration {
    name                 = var.ip_configuration_name
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = var.public_ip_id
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }

  lifecycle {
    precondition {
      condition     = var.sku != "Basic" || (!var.file_copy_enabled && !var.ip_connect_enabled && !var.tunneling_enabled && var.scale_units == 2)
      error_message = "Basic SKU does not support advanced Bastion capabilities or custom scale units."
    }
  }
}
