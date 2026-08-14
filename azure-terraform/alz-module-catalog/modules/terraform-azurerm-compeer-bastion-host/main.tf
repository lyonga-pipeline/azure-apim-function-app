resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.public_ip_zones
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                   = var.name
  resource_group_name    = var.resource_group_name
  location               = var.location
  sku                    = var.sku
  copy_paste_enabled     = var.copy_paste_enabled
  file_copy_enabled      = var.file_copy_enabled
  ip_connect_enabled     = var.ip_connect_enabled
  shareable_link_enabled = var.shareable_link_enabled
  tunneling_enabled      = var.tunneling_enabled
  scale_units            = var.scale_units
  tags                   = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.key
  target_resource_id             = azurerm_bastion_host.this.id
  log_analytics_workspace_id     = try(each.value.log_analytics_workspace_id, null)
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
