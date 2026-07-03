resource "azurerm_storage_share" "this" {
  for_each           = var.shares
  name               = each.key
  storage_account_id = var.storage_account_id
  quota              = try(each.value.quota, 100)
  access_tier        = try(each.value.access_tier, null)
  metadata           = try(each.value.metadata, null)
}
