data "azurerm_client_config" "current" {}

data "azurerm_storage_account" "storage_account" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}