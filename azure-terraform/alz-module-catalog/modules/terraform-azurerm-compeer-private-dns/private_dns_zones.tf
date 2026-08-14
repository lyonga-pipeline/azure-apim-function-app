resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name

  dynamic "soa_record" {
    for_each = var.soa_record
    content {
      email        = lookup(soa_record.value, "email", null)
      expire_time  = lookup(soa_record.value, "expire_time", null)
      minimum_ttl  = lookup(soa_record.value, "minimum_ttl", null)
      refresh_time = lookup(soa_record.value, "refresh_time", null)
      retry_time   = lookup(soa_record.value, "retry_time", null)
      ttl          = lookup(soa_record.value, "ttl", null)
      tags         = lookup(soa_record.value, "tags", null)
    }
  }
  tags = var.private_dns_zone_tags
}
