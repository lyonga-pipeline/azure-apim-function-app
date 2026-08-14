/**
## Managing Azure App Configuration Key
*/
resource "azurerm_app_configuration_key" "app_config_key" {
  count                  = var.create_app_config_key ? 1 : 0
  configuration_store_id = local.configuration_store_id
  key                    = var.app_config_key_name
  label                  = var.app_config_key_label
  locked                 = var.app_config_key_locked
  type                   = var.app_config_key_type

  # Conditional assignments for attributes
  content_type        = var.app_config_key_type == "kv" ? var.app_config_key_content_type : null
  value               = var.app_config_key_type == "kv" ? var.app_config_key_value : null
  vault_key_reference = var.app_config_key_type == "vault" ? var.app_config_key_vault_key_reference : null

  tags = var.app_config_key_tags
}
