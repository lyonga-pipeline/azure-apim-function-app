# Private DNS zones + their VNet links.
#
# Ownership boundary: zones and links only. A-records and other record sets are
# owned by terraform-azurerm-compeer-private-dns-a-record and friends.

resource "azurerm_private_dns_zone" "this" {
  for_each = var.zones

  name                = each.key
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_group_name)
  tags                = merge(var.tags, each.value.tags)

  dynamic "soa_record" {
    for_each = each.value.soa_record == null ? [] : [each.value.soa_record]
    content {
      email        = soa_record.value.email
      expire_time  = soa_record.value.expire_time
      minimum_ttl  = soa_record.value.minimum_ttl
      refresh_time = soa_record.value.refresh_time
      retry_time   = soa_record.value.retry_time
      ttl          = soa_record.value.ttl
      tags         = soa_record.value.tags
    }
  }
}

locals {
  # Flatten { zone_key => { link_key => link } } into a single keyed map with a
  # stable "zone/link" composite key so adding a link never touches other links.
  vnet_links = merge([
    for zk, z in var.zones : {
      for lk, l in z.vnet_links : "${zk}/${lk}" => {
        zone_key             = zk
        name                 = coalesce(l.name, lk)
        resource_group_name  = coalesce(l.resource_group_name, z.resource_group_name, var.resource_group_name)
        virtual_network_id   = l.virtual_network_id
        registration_enabled = l.registration_enabled
        tags                 = merge(var.tags, l.tags)
      }
    }
  ]...)
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = local.vnet_links

  name                  = each.value.name
  resource_group_name   = each.value.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.value.zone_key].name
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = each.value.registration_enabled
  tags                  = each.value.tags
}
