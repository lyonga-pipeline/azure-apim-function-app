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
# Removed from this resource module: azurerm_automation_runbook.this is a companion lifecycle capability.


# Automation Webhook
# Removed from this resource module: azurerm_automation_webhook.this is a companion lifecycle capability.
