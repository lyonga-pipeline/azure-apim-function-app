module "tags" {
  source = "../../modules/terraform-azurerm-compeer-platform-tags"

  environment         = var.environment
  application         = var.platform_tags.application
  business_owner      = var.platform_tags.business_owner
  source_repo         = var.platform_tags.source_repo
  terraform_workspace = var.platform_tags.terraform_workspace
  recovery_tier       = var.platform_tags.recovery_tier
  cost_center         = var.platform_tags.cost_center
  data_classification = var.platform_tags.data_classification
  compliance_boundary = var.platform_tags.compliance_boundary
  additional_tags     = var.platform_tags.additional_tags
}

module "resource_group" {
  source = "../../modules/terraform-azurerm-compeer-resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

locals {
  expressroute_posture_enabled = coalesce(try(var.expressroute_posture.enabled, null), false)
  expressroute_posture = {
    onpremises_required       = coalesce(try(var.expressroute_posture.onpremises_required, null), true)
    provider_design_reference = try(var.expressroute_posture.provider_design_reference, null)
    bgp_and_routing_approved  = coalesce(try(var.expressroute_posture.bgp_and_routing_approved, null), false)
    cutover_window_approved   = coalesce(try(var.expressroute_posture.cutover_window_approved, null), false)
    notes                     = try(var.expressroute_posture.notes, null)
  }

  vpn_posture_enabled = coalesce(try(var.vpn_posture.enabled, null), false)
  vpn_posture = {
    backup_required              = coalesce(try(var.vpn_posture.backup_required, null), true)
    design_reference             = try(var.vpn_posture.design_reference, null)
    bgp_and_routing_approved     = coalesce(try(var.vpn_posture.bgp_and_routing_approved, null), false)
    shared_key_handling_approved = coalesce(try(var.vpn_posture.shared_key_handling_approved, null), false)
    failover_test_approved       = coalesce(try(var.vpn_posture.failover_test_approved, null), false)
    notes                        = try(var.vpn_posture.notes, null)
  }
}

resource "terraform_data" "expressroute_contract" {
  input = {
    enabled                   = local.expressroute_posture_enabled
    onpremises_required       = local.expressroute_posture.onpremises_required
    provider_design_reference = local.expressroute_posture.provider_design_reference
    bgp_and_routing_approved  = local.expressroute_posture.bgp_and_routing_approved
    cutover_window_approved   = local.expressroute_posture.cutover_window_approved
    circuit_count             = length(var.expressroute_circuits)
    gateway_public_ip_count   = length(var.gateway_public_ips)
    gateway_enabled           = var.expressroute_gateway != null
    connection_count          = length(var.expressroute_connections)
    notes                     = local.expressroute_posture.notes
  }

  lifecycle {
    precondition {
      condition = (
        !local.expressroute_posture_enabled ||
        (
          length(var.expressroute_circuits) > 0 &&
          length(var.gateway_public_ips) > 0 &&
          var.expressroute_gateway != null &&
          length(var.expressroute_connections) > 0
        )
      )
      error_message = "When ExpressRoute posture is enabled, configure at least one circuit, gateway public IP, ExpressRoute gateway, and connection."
    }

    precondition {
      condition = (
        !local.expressroute_posture_enabled ||
        (
          length(trimspace(coalesce(local.expressroute_posture.provider_design_reference, ""))) > 0 &&
          local.expressroute_posture.bgp_and_routing_approved &&
          local.expressroute_posture.cutover_window_approved
        )
      )
      error_message = "When ExpressRoute posture is enabled, provider design reference, BGP/routing approval, and cutover approval must be captured."
    }
  }
}

resource "terraform_data" "vpn_contract" {
  input = {
    enabled                      = local.vpn_posture_enabled
    backup_required              = local.vpn_posture.backup_required
    design_reference             = local.vpn_posture.design_reference
    bgp_and_routing_approved     = local.vpn_posture.bgp_and_routing_approved
    shared_key_handling_approved = local.vpn_posture.shared_key_handling_approved
    failover_test_approved       = local.vpn_posture.failover_test_approved
    gateway_public_ip_count      = length(var.vpn_gateway_public_ips)
    gateway_enabled              = var.vpn_gateway != null
    local_network_gateway_count  = length(var.local_network_gateways)
    connection_count             = length(var.vpn_connections)
    notes                        = local.vpn_posture.notes
  }

  lifecycle {
    precondition {
      condition = (
        !local.vpn_posture_enabled ||
        (
          length(var.vpn_gateway_public_ips) > 0 &&
          var.vpn_gateway != null &&
          length(var.local_network_gateways) > 0 &&
          length(var.vpn_connections) > 0
        )
      )
      error_message = "When VPN posture is enabled, configure at least one VPN gateway public IP, VPN gateway, local network gateway, and VPN connection."
    }

    precondition {
      condition = (
        !local.vpn_posture_enabled ||
        (
          length(trimspace(coalesce(local.vpn_posture.design_reference, ""))) > 0 &&
          local.vpn_posture.bgp_and_routing_approved &&
          local.vpn_posture.shared_key_handling_approved &&
          local.vpn_posture.failover_test_approved
        )
      )
      error_message = "When VPN posture is enabled, VPN design reference, BGP/routing approval, shared-key handling approval, and failover-test approval must be captured."
    }
  }
}

module "expressroute_circuits" {
  source   = "../../modules/terraform-azurerm-compeer-expressroute-circuit"
  for_each = var.expressroute_circuits

  name                     = each.value.name
  resource_group_name      = module.resource_group.name
  location                 = var.location
  service_provider_name    = each.value.service_provider_name
  peering_location         = each.value.peering_location
  bandwidth_in_mbps        = each.value.bandwidth_in_mbps
  allow_classic_operations = try(each.value.allow_classic_operations, false)
  sku                      = each.value.sku
  tags                     = module.tags.tags
}

module "gateway_public_ips" {
  source   = "../../modules/terraform-azurerm-compeer-public-ip"
  for_each = var.gateway_public_ips

  name                = each.value.name
  resource_group_name = module.resource_group.name
  location            = var.location
  allocation_method   = try(each.value.allocation_method, "Static")
  sku                 = try(each.value.sku, "Standard")
  sku_tier            = try(each.value.sku_tier, "Regional")
  zones               = try(each.value.zones, [])
  tags                = module.tags.tags
}

module "expressroute_gateway" {
  source = "../../modules/terraform-azurerm-compeer-virtual-network-gateway"
  count  = var.expressroute_gateway == null ? 0 : 1

  name                = var.expressroute_gateway.name
  resource_group_name = module.resource_group.name
  location            = var.location
  type                = "ExpressRoute"
  sku                 = try(var.expressroute_gateway.sku, "ErGw1AZ")
  active_active       = try(var.expressroute_gateway.active_active, false)
  enable_bgp          = try(var.expressroute_gateway.enable_bgp, true)
  ip_configurations = {
    for key, value in var.expressroute_gateway.ip_configurations : key => {
      public_ip_address_id          = module.gateway_public_ips[value.public_ip_key].id
      subnet_id                     = value.gateway_subnet_id
      private_ip_address_allocation = try(value.private_ip_address_allocation, "Dynamic")
    }
  }
  tags = module.tags.tags
}

module "expressroute_connections" {
  source   = "../../modules/terraform-azurerm-compeer-virtual-network-gateway-connection"
  for_each = var.expressroute_connections

  name                       = each.value.name
  resource_group_name        = module.resource_group.name
  location                   = var.location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = module.expressroute_gateway[0].id
  express_route_circuit_id   = module.expressroute_circuits[each.value.circuit_key].id
  authorization_key          = try(each.value.authorization_key, null)
  routing_weight             = try(each.value.routing_weight, 0)
  tags                       = module.tags.tags
}

module "vpn_gateway_public_ips" {
  source   = "../../modules/terraform-azurerm-compeer-public-ip"
  for_each = var.vpn_gateway_public_ips

  name                = each.value.name
  resource_group_name = module.resource_group.name
  location            = var.location
  allocation_method   = try(each.value.allocation_method, "Static")
  sku                 = try(each.value.sku, "Standard")
  sku_tier            = try(each.value.sku_tier, "Regional")
  zones               = try(each.value.zones, [])
  tags                = module.tags.tags
}

module "vpn_gateway" {
  source = "../../modules/terraform-azurerm-compeer-virtual-network-gateway"
  count  = var.vpn_gateway == null ? 0 : 1

  name                = var.vpn_gateway.name
  resource_group_name = module.resource_group.name
  location            = var.location
  type                = "Vpn"
  vpn_type            = try(var.vpn_gateway.vpn_type, "RouteBased")
  sku                 = try(var.vpn_gateway.sku, "VpnGw1AZ")
  active_active       = try(var.vpn_gateway.active_active, false)
  enable_bgp          = try(var.vpn_gateway.enable_bgp, false)
  generation          = try(var.vpn_gateway.generation, null)
  ip_configurations = {
    for key, value in var.vpn_gateway.ip_configurations : key => {
      public_ip_address_id          = module.vpn_gateway_public_ips[value.public_ip_key].id
      subnet_id                     = value.gateway_subnet_id
      private_ip_address_allocation = try(value.private_ip_address_allocation, "Dynamic")
    }
  }
  tags = module.tags.tags
}

module "local_network_gateways" {
  source = "../../modules/terraform-azurerm-compeer-local-network-gateway"

  local_network_gateways = {
    for key, value in var.local_network_gateways : key => {
      name                = value.name
      resource_group_name = module.resource_group.name
      location            = var.location
      gateway_address     = value.gateway_address
      address_space       = value.address_space
      bgp_settings        = try(value.bgp_settings, null)
      timeouts            = try(value.timeouts, {})
      tags                = module.tags.tags
    }
  }
}

module "vpn_connections" {
  source   = "../../modules/terraform-azurerm-compeer-virtual-network-gateway-connection"
  for_each = var.vpn_connections

  name                               = each.value.name
  resource_group_name                = module.resource_group.name
  location                           = var.location
  type                               = "IPsec"
  virtual_network_gateway_id         = module.vpn_gateway[0].id
  local_network_gateway_id           = module.local_network_gateways.ids[each.value.local_network_gateway_key]
  shared_key                         = try(each.value.shared_key, null)
  routing_weight                     = try(each.value.routing_weight, 0)
  connection_mode                    = try(each.value.connection_mode, null)
  connection_protocol                = try(each.value.connection_protocol, null)
  dpd_timeout_seconds                = try(each.value.dpd_timeout_seconds, null)
  enable_bgp                         = try(each.value.enable_bgp, null)
  use_policy_based_traffic_selectors = try(each.value.use_policy_based_traffic_selectors, null)
  local_azure_ip_address_enabled     = try(each.value.local_azure_ip_address_enabled, null)
  private_link_fast_path_enabled     = try(each.value.private_link_fast_path_enabled, null)
  egress_nat_rule_ids                = try(each.value.egress_nat_rule_ids, null)
  ingress_nat_rule_ids               = try(each.value.ingress_nat_rule_ids, null)
  custom_bgp_addresses               = try(each.value.custom_bgp_addresses, null)
  ipsec_policy                       = try(each.value.ipsec_policy, null)
  traffic_selector_policies          = try(each.value.traffic_selector_policies, {})
  timeouts                           = try(each.value.timeouts, {})
  tags                               = module.tags.tags
}
