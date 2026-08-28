locals {
  tags = merge({
    ManagedBy = "Terraform"
    IaCSource = "CompeerHCP"
    Phase     = "1"
  }, var.tags)

  circuit_peerings = merge({}, [
    for circuit_key, circuit in var.expressroute_circuits : {
      for peering_key, peering in try(circuit.peerings, {}) : "${circuit_key}-${peering_key}" => merge(peering, {
        circuit_key = circuit_key
      })
    }
  ]...)

  circuit_authorizations = merge({}, [
    for circuit_key, circuit in var.expressroute_circuits : {
      for authorization_key, authorization in try(circuit.authorizations, {}) : "${circuit_key}-${authorization_key}" => merge(authorization, {
        circuit_key = circuit_key
      })
    }
  ]...)
}

module "expressroute_circuit" {
  for_each = var.expressroute_circuits
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-expressroute-circuit/azurerm"
  version  = "1.0.0"

  name                     = each.value.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  service_provider_name    = each.value.service_provider_name
  peering_location         = each.value.peering_location
  bandwidth_in_mbps        = each.value.bandwidth_in_mbps
  allow_classic_operations = try(each.value.allow_classic_operations, false)
  sku                      = try(each.value.sku, { tier = "Standard", family = "MeteredData" })
  tags                     = local.tags
}

resource "azurerm_express_route_circuit_peering" "this" {
  for_each = local.circuit_peerings

  resource_group_name           = var.resource_group_name
  express_route_circuit_name    = module.expressroute_circuit[each.value.circuit_key].name
  peering_type                  = each.value.peering_type
  vlan_id                       = each.value.vlan_id
  peer_asn                      = try(each.value.peer_asn, null)
  primary_peer_address_prefix   = try(each.value.primary_peer_address_prefix, null)
  secondary_peer_address_prefix = try(each.value.secondary_peer_address_prefix, null)
  shared_key                    = try(each.value.shared_key, null)
  route_filter_id               = try(each.value.route_filter_id, null)
  ipv4_enabled                  = try(each.value.ipv4_enabled, true)

  dynamic "microsoft_peering_config" {
    for_each = try(each.value.microsoft_peering_config, null) == null ? [] : [each.value.microsoft_peering_config]
    content {
      advertised_public_prefixes = microsoft_peering_config.value.advertised_public_prefixes
      advertised_communities     = try(microsoft_peering_config.value.advertised_communities, null)
      customer_asn               = try(microsoft_peering_config.value.customer_asn, null)
      routing_registry_name      = try(microsoft_peering_config.value.routing_registry_name, null)
    }
  }

  dynamic "ipv6" {
    for_each = try(each.value.ipv6, null) == null ? [] : [each.value.ipv6]
    content {
      enabled                       = try(ipv6.value.enabled, true)
      primary_peer_address_prefix   = ipv6.value.primary_peer_address_prefix
      secondary_peer_address_prefix = ipv6.value.secondary_peer_address_prefix
      route_filter_id               = try(ipv6.value.route_filter_id, null)

      dynamic "microsoft_peering" {
        for_each = try(ipv6.value.microsoft_peering, null) == null ? [] : [ipv6.value.microsoft_peering]
        content {
          advertised_public_prefixes = try(microsoft_peering.value.advertised_public_prefixes, null)
          advertised_communities     = try(microsoft_peering.value.advertised_communities, null)
          customer_asn               = try(microsoft_peering.value.customer_asn, null)
          routing_registry_name      = try(microsoft_peering.value.routing_registry_name, null)
        }
      }
    }
  }
}

resource "azurerm_express_route_circuit_authorization" "this" {
  for_each = local.circuit_authorizations

  name                       = each.value.name
  resource_group_name        = var.resource_group_name
  express_route_circuit_name = module.expressroute_circuit[each.value.circuit_key].name
}

module "gateway_connection" {
  for_each = var.gateway_connections
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-virtual-network-gateway-connection/azurerm"
  version  = "1.0.0"

  name                       = each.value.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = each.value.virtual_network_gateway_id
  express_route_circuit_id   = coalesce(try(each.value.express_route_circuit_id, null), try(module.expressroute_circuit[each.value.express_route_circuit_key].id, null))
  authorization_key          = try(each.value.authorization_key, null)
  routing_weight             = try(each.value.routing_weight, 0)
  tags                       = local.tags
}
