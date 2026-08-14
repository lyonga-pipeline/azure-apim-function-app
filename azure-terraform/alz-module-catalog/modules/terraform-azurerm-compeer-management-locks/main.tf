resource "azurerm_management_lock" "this" {
  for_each = var.locks

  name       = coalesce(try(each.value.name, null), "${each.key}-lock")
  scope      = each.value.scope
  lock_level = try(each.value.lock_level, "CanNotDelete")
  notes      = try(each.value.notes, null)
}
