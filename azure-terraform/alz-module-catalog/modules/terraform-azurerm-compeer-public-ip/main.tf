resource "azurerm_public_ip" "ip" {
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

    # Documented azurerm_public_ip constraints (provider docs): zones need a
    # Standard SKU, Global tier needs Standard SKU, and a DDoS plan can only
    # be attached when ddos_protection_mode is Enabled.
    precondition {
      condition     = length(var.zones) == 0 ? true : var.sku == "Standard"
      error_message = "zones can only be set on a Standard SKU public IP."
    }

    precondition {
      condition     = var.sku_tier != "Global" ? true : var.sku == "Standard"
      error_message = "sku_tier = Global requires sku = Standard."
    }

    precondition {
      condition     = var.ddos_protection_plan_id == null ? true : var.ddos_protection_mode == "Enabled"
      error_message = "ddos_protection_plan_id can only be set when ddos_protection_mode is Enabled."
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}
