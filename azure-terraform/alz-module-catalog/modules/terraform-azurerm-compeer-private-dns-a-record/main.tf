resource "azurerm_private_dns_a_record" "this" {
  for_each = var.records

  name                = each.value.name
  zone_name           = each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = try(each.value.ttl, 300)
  records             = each.value.records
  tags                = merge(var.tags, try(each.value.tags, {}))
}
