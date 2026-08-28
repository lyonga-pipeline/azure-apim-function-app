resource "azurerm_public_ip" "this" {
  count = var.public_ip_id == null ? 1 : 0

  name                    = coalesce(try(var.public_ip.name, null), "${var.name}-pip")
  resource_group_name     = var.resource_group_name
  location                = var.location
  allocation_method       = try(var.public_ip.allocation_method, "Static")
  sku                     = try(var.public_ip.sku, "Standard")
  sku_tier                = try(var.public_ip.sku_tier, "Regional")
  domain_name_label       = try(var.public_ip.domain_name_label, null)
  ip_version              = try(var.public_ip.ip_version, "IPv4")
  idle_timeout_in_minutes = try(var.public_ip.idle_timeout_in_minutes, 4)
  public_ip_prefix_id     = try(var.public_ip.public_ip_prefix_id, null)
  reverse_fqdn            = try(var.public_ip.reverse_fqdn, null)
  zones                   = try(var.public_ip.zones, var.public_ip_zones)
  tags                    = merge(var.tags, try(var.public_ip.tags, {}))
}

locals {
  public_ip_id = var.public_ip_id == null ? azurerm_public_ip.this[0].id : var.public_ip_id
}

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
    name                 = "configuration"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = local.public_ip_id
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.key
  target_resource_id             = azurerm_bastion_host.this.id
  log_analytics_workspace_id     = try(each.value.log_analytics_workspace_id, null)
  log_analytics_destination_type = try(each.value.log_analytics_destination_type, null)
  storage_account_id             = try(each.value.storage_account_id, null)
  eventhub_authorization_rule_id = try(each.value.eventhub_authorization_rule_id, null)
  eventhub_name                  = try(each.value.eventhub_name, null)

  dynamic "enabled_log" {
    for_each = try(each.value.logs, ["BastionAuditLogs"])
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = try(each.value.metrics, ["AllMetrics"])
    content {
      category = enabled_metric.value
    }
  }
}
