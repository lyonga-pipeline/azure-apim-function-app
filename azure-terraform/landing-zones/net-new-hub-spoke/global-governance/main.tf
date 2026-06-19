resource "azurerm_management_group" "this" {
  for_each = var.management_groups

  name                       = each.key
  display_name               = each.value.display_name
  parent_management_group_id = each.value.parent_key == "root" ? var.root_management_group_id : azurerm_management_group.this[each.value.parent_key].id
}

resource "azurerm_management_group_subscription_association" "this" {
  for_each = var.subscription_placements

  management_group_id = azurerm_management_group.this[each.value.management_group_key].id
  subscription_id     = each.value.subscription_id
}

