# Automation account creation
resource "azurerm_automation_account" "this" {
  name                          = var.automation_account_name
  resource_group_name           = var.resource_group_name
  location                      = var.resource_group_location
  sku_name                      = var.automation_account_sku
  local_authentication_enabled  = var.local_auth_enabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
}

# Automation account Runbook creation
resource "azurerm_automation_runbook" "this" {
  for_each                = var.runbook_configuration
  name                    = each.value.runbook_name
  resource_group_name     = var.resource_group_name
  location                = var.resource_group_location
  automation_account_name = azurerm_automation_account.this.name
  log_progress            = each.value.runbook_log_progress
  log_verbose             = each.value.runbook_log_verbose
  runbook_type            = each.value.runbook_type
  content                 = data.local_file.runbook_content[each.key].content
  #content                 = var.runbook_content
}

# Automation Webhook
resource "azurerm_automation_webhook" "this" {
  count                   = var.create_runbook_webhook ? 1 : 0
  name                    = var.webhook_name
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  expiry_time             = var.expiry_time
  enabled                 = var.webhook_enabled
  runbook_name            = azurerm_automation_runbook.this.name
  parameters              = var.webhook_parameters
}