resource "azurerm_resource_group" "groups" {
  for_each = var.resource_groups

  name     = each.value.name
  location = each.value.location
  tags     = try(each.value.tags, {})
}

moved {
  from = azurerm_resource_group.group
  to   = azurerm_resource_group.groups["main"]
}
