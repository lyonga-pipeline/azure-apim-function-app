resource "azurerm_storage_container" "this" {
  for_each              = var.containers
  name                  = each.key
  storage_account_name  = var.storage_account_name
  container_access_type = try(each.value.container_access_type, "private")
  metadata              = try(each.value.metadata, null)
}
