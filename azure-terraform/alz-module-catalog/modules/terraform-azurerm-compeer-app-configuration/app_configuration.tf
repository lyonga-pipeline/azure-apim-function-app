/**
## Managing Azure App Configuration
*/
resource "azurerm_app_configuration" "app_config" {
  count                      = var.create_app_config ? 1 : 0
  name                       = var.app_config_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  sku                        = var.app_config_sku
  local_auth_enabled         = var.app_config_local_auth
  public_network_access      = var.app_config_public_access
  purge_protection_enabled   = var.app_config_purge_protection
  soft_delete_retention_days = var.app_config_soft_delete_retention_days
  dynamic "identity" {
    for_each = var.identity != null ? var.identity : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  dynamic "encryption" {
    for_each = var.encryption != null ? var.encryption : []
    content {
      key_vault_key_identifier = encryption.value.key_vault_key_identifier
      identity_client_id       = encryption.value.identity_client_id
    }
  }
  tags = var.app_config_tags
}
