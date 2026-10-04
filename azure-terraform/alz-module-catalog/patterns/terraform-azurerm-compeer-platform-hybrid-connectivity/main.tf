module "tags" {
  source = "../../modules/terraform-azurerm-compeer-platform-tags"

  environment           = var.environment
  application           = var.platform_tags.application
  appcode               = var.platform_tags.appcode
  owner                 = var.platform_tags.owner
  source_repo           = var.platform_tags.source_repo
  created_on            = var.platform_tags.created_on
  criticality_tier      = var.platform_tags.criticality_tier
  data_classification   = var.platform_tags.data_classification
  lifecycle_state       = var.platform_tags.lifecycle_state
  cost_center           = var.platform_tags.cost_center
  gl_category           = var.platform_tags.gl_category
  application_component = var.platform_tags.application_component
  modified_on           = var.platform_tags.modified_on
  created_by            = var.platform_tags.created_by
  dr_tier               = var.platform_tags.dr_tier
  expiration_date       = var.platform_tags.expiration_date
  time_bound_exception  = var.platform_tags.time_bound_exception
  additional_tags       = var.platform_tags.additional_tags
}

module "naming" {
  source = "../../modules/terraform-azurerm-compeer-naming"

  region               = coalesce(try(var.naming.region, null), var.location)
  environment          = coalesce(try(var.naming.environment, null), var.environment)
  scope                = try(var.naming.scope, "platform")
  component            = coalesce(try(var.naming.component, null), "hybrid")
  domain               = try(var.naming.domain, null)
  appcode              = try(var.naming.appcode, null)
  abbreviation         = try(var.naming.abbreviation, null)
  key_vault_name_token = try(var.naming.key_vault_name_token, "vault")

  storage_uniqueness = try(var.naming.storage_uniqueness, "")
  public_ip_keys     = concat(keys(var.gateway_public_ips), keys(var.route_server_public_ips))
}

module "resource_group" {
  source = "../../modules/terraform-azurerm-compeer-resource-group"

  resource_groups = {
    main = {
      name     = coalesce(try(var.resource_group.name, null), module.naming.resource_group)
      location = var.location
      tags     = module.tags.tags
    }
  }
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
      # coalesce(x, "") errors ("no non-null, non-empty-string arguments")
      # whenever x is null, because coalesce treats "" as empty too - it
      # doesn't return "". That crashed terraform plan for every run of this
      # pattern once provider_design_reference was left unset, regardless of
      # whether the posture was even enabled (HCL evaluates this expression
      # eagerly; the leading !enabled short-circuit does not protect the
      # error inside coalesce). A null-safe ternary avoids the error path.
      condition = (
        !local.expressroute_posture_enabled ||
        (
          length(trimspace(local.expressroute_posture.provider_design_reference == null ? "" : local.expressroute_posture.provider_design_reference)) > 0 &&
          local.expressroute_posture.bgp_and_routing_approved &&
          local.expressroute_posture.cutover_window_approved
        )
      )
      error_message = "When ExpressRoute posture is enabled, provider design reference, BGP/routing approval, and cutover approval must be captured."
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

  name                = coalesce(try(each.value.name, null), module.naming.public_ip_names[each.key])
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

  name                = coalesce(try(var.expressroute_gateway.name, null), module.naming.expressroute_gateway)
  resource_group_name = module.resource_group.name
  location            = var.location
  type                = "ExpressRoute"
  sku                 = try(var.expressroute_gateway.sku, "ErGw1AZ")
  active_active       = try(var.expressroute_gateway.active_active, false)
  bgp_enabled         = coalesce(try(var.expressroute_gateway.bgp_enabled, null), try(var.expressroute_gateway.enable_bgp, null), true)
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

module "route_server_public_ips" {
  source   = "../../modules/terraform-azurerm-compeer-public-ip"
  for_each = var.route_server_public_ips

  name                = coalesce(try(each.value.name, null), module.naming.public_ip_names[each.key])
  resource_group_name = module.resource_group.name
  location            = var.location
  allocation_method   = try(each.value.allocation_method, "Static")
  sku                 = try(each.value.sku, "Standard")
  sku_tier            = try(each.value.sku_tier, "Regional")
  zones               = try(each.value.zones, [])
  tags                = module.tags.tags
}

module "route_servers" {
  source = "../../modules/terraform-azurerm-compeer-route-server"

  route_servers = {
    for key, value in var.route_servers : key => {
      name = coalesce(
        try(value.name, null),
        key == "primary" ? module.naming.route_server : "${module.naming.route_server}-${key}"
      )
      resource_group_name              = module.resource_group.name
      location                         = var.location
      sku                              = try(value.sku, "Standard")
      subnet_id                        = value.subnet_id
      public_ip_address_id             = coalesce(try(value.public_ip_address_id, null), try(module.route_server_public_ips[value.public_ip_key].id, null))
      branch_to_branch_traffic_enabled = try(value.branch_to_branch_traffic_enabled, true)
      tags                             = module.tags.tags
      timeouts                         = try(value.timeouts, {})
      bgp_connections                  = try(value.bgp_connections, {})
    }
  }
}
