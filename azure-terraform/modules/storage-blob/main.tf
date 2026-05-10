resource "azurerm_storage_blob" "this" {
  for_each               = var.blobs
  name                   = each.key
  storage_account_name   = var.storage_account_name
  storage_container_name = each.value.container_name
  type                   = try(each.value.type, "Block")
  source                 = try(each.value.source, null)
  size                   = try(each.value.size, null)
  content_type           = try(each.value.content_type, null)
  metadata               = try(each.value.metadata, null)
}
