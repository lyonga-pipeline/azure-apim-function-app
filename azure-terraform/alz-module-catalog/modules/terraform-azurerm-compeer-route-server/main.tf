locals {
  bgp_connection_list = flatten([
    for route_server_key, route_server in var.route_servers : [
      for connection_key, connection in try(route_server.bgp_connections, {}) :
      merge(connection, {
        key              = "${route_server_key}-${connection_key}"
        route_server_key = route_server_key
      })
    ]
  ])

  bgp_connections = {
    for connection in local.bgp_connection_list : connection.key => connection
  }
}

resource "azurerm_route_server" "this" {
  for_each = var.route_servers

  name                             = each.value.name
  resource_group_name              = each.value.resource_group_name
  location                         = each.value.location
  sku                              = try(each.value.sku, "Standard")
  subnet_id                        = each.value.subnet_id
  public_ip_address_id             = each.value.public_ip_address_id
  branch_to_branch_traffic_enabled = try(each.value.branch_to_branch_traffic_enabled, true)
  tags                             = try(each.value.tags, {})
}

resource "azurerm_route_server_bgp_connection" "this" {
  for_each = local.bgp_connections

  name            = each.value.name
  route_server_id = coalesce(try(each.value.ipv4_route_server_id, null), azurerm_route_server.this[each.value.route_server_key].id)
  peer_asn        = each.value.peer_asn
  peer_ip         = each.value.peer_ip
}
