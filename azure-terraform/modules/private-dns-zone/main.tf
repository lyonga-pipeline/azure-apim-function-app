resource "azurerm_private_dns_zone" "this" {
  for_each            = var.zones
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  tags                = merge(var.tags, try(each.value.tags, {}))
}
