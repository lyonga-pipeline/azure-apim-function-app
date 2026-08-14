resource "azurerm_local_network_gateway" "this" {
  for_each = var.local_network_gateways

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  gateway_address     = each.value.gateway_address
  address_space       = each.value.address_space
  tags                = try(each.value.tags, {})

  dynamic "bgp_settings" {
    for_each = try(each.value.bgp_settings, null) == null ? [] : [each.value.bgp_settings]
    content {
      asn                 = bgp_settings.value.asn
      bgp_peering_address = bgp_settings.value.bgp_peering_address
      peer_weight         = try(bgp_settings.value.peer_weight, null)
    }
  }
}
