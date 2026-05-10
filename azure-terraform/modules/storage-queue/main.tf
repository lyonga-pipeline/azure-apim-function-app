resource "azurerm_storage_queue" "this" {
  for_each             = var.queues
  name                 = each.key
  storage_account_name = var.storage_account_name
  metadata             = try(each.value.metadata, null)
}
