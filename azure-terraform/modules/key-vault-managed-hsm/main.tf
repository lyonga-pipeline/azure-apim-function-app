resource "azurerm_key_vault_managed_hardware_security_module" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = var.sku_name
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = var.public_network_access_enabled
  admin_object_ids              = var.admin_object_ids
  tags                          = var.tags

  network_acls {
    bypass         = var.network_acls.bypass
    default_action = var.network_acls.default_action
  }
}
