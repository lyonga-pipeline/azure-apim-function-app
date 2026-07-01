module "tags" {
  source = "../../../modules/platform-tags"

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
  source = "../../../modules/resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

module "expressroute_circuits" {
  source   = "../../../modules/expressroute-circuit"
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
  source   = "../../../modules/public-ip"
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
  source = "../../../modules/virtual-network-gateway"
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
  source   = "../../../modules/virtual-network-gateway-connection"
  for_each = var.expressroute_connections

  name                       = each.value.name
  resource_group_name        = module.resource_group.name
  location                   = var.location
  virtual_network_gateway_id = module.expressroute_gateway[0].id
  express_route_circuit_id   = module.expressroute_circuits[each.value.circuit_key].id
  authorization_key          = try(each.value.authorization_key, null)
  routing_weight             = try(each.value.routing_weight, 0)
  tags                       = module.tags.tags
}
