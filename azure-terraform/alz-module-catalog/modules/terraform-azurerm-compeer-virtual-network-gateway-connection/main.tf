resource "azurerm_virtual_network_gateway_connection" "this" {
  name                               = var.name
  resource_group_name                = var.resource_group_name
  location                           = var.location
  type                               = var.type
  virtual_network_gateway_id         = var.virtual_network_gateway_id
  express_route_circuit_id           = var.express_route_circuit_id
  local_network_gateway_id           = var.local_network_gateway_id
  peer_virtual_network_gateway_id    = var.peer_virtual_network_gateway_id
  authorization_key                  = var.authorization_key
  shared_key                         = var.shared_key
  routing_weight                     = var.routing_weight
  connection_mode                    = var.connection_mode
  connection_protocol                = var.connection_protocol
  dpd_timeout_seconds                = var.dpd_timeout_seconds
  enable_bgp                         = var.enable_bgp
  express_route_gateway_bypass       = var.express_route_gateway_bypass
  use_policy_based_traffic_selectors = var.use_policy_based_traffic_selectors
  egress_nat_rule_ids                = var.egress_nat_rule_ids
  ingress_nat_rule_ids               = var.ingress_nat_rule_ids
  local_azure_ip_address_enabled     = var.local_azure_ip_address_enabled
  private_link_fast_path_enabled     = var.private_link_fast_path_enabled
  tags                               = var.tags

  dynamic "custom_bgp_addresses" {
    for_each = var.custom_bgp_addresses == null ? [] : [var.custom_bgp_addresses]
    content {
      primary   = custom_bgp_addresses.value.primary
      secondary = try(custom_bgp_addresses.value.secondary, null)
    }
  }

  dynamic "ipsec_policy" {
    for_each = var.ipsec_policy == null ? [] : [var.ipsec_policy]
    content {
      dh_group         = ipsec_policy.value.dh_group
      ike_encryption   = ipsec_policy.value.ike_encryption
      ike_integrity    = ipsec_policy.value.ike_integrity
      ipsec_encryption = ipsec_policy.value.ipsec_encryption
      ipsec_integrity  = ipsec_policy.value.ipsec_integrity
      pfs_group        = ipsec_policy.value.pfs_group
      sa_datasize      = try(ipsec_policy.value.sa_datasize, null)
      sa_lifetime      = try(ipsec_policy.value.sa_lifetime, null)
    }
  }

  dynamic "traffic_selector_policy" {
    for_each = var.traffic_selector_policies
    content {
      local_address_cidrs  = traffic_selector_policy.value.local_address_cidrs
      remote_address_cidrs = traffic_selector_policy.value.remote_address_cidrs
    }
  }

  lifecycle {
    precondition {
      condition = contains([
        "ExpressRoute",
        "IPsec",
        "Vnet2Vnet"
      ], var.type)
      error_message = "type must be ExpressRoute, IPsec, or Vnet2Vnet."
    }

    precondition {
      condition = (
        (var.type == "ExpressRoute" && var.express_route_circuit_id != null && var.local_network_gateway_id == null && var.peer_virtual_network_gateway_id == null) ||
        (var.type == "IPsec" && var.local_network_gateway_id != null && var.express_route_circuit_id == null && var.peer_virtual_network_gateway_id == null) ||
        (var.type == "Vnet2Vnet" && var.peer_virtual_network_gateway_id != null && var.express_route_circuit_id == null && var.local_network_gateway_id == null)
      )
      error_message = "Set the matching remote endpoint for the connection type: express_route_circuit_id for ExpressRoute, local_network_gateway_id for IPsec, or peer_virtual_network_gateway_id for Vnet2Vnet."
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}
