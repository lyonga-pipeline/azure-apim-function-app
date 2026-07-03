resource "azurerm_storage_queue" "this" {
  for_each           = var.queues
  name               = each.key
  storage_account_id = var.storage_account_id
  metadata           = try(each.value.metadata, null)
}
