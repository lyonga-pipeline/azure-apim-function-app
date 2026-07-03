resource "azurerm_storage_table" "this" {
  for_each           = var.tables
  name               = each.key
  storage_account_id = var.storage_account_id
}
