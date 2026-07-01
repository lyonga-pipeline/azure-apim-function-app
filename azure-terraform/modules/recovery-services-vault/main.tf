resource "azurerm_recovery_services_vault" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  soft_delete_enabled = var.soft_delete_enabled
  storage_mode_type   = var.storage_mode_type
  tags                = var.tags
}
