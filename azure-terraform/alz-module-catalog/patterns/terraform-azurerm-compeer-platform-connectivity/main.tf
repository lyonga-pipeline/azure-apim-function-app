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
  ddos_protection_plan_enabled = coalesce(try(var.ddos_protection_plan.enabled, null), false)
  ddos_protection_plan_id = try(coalesce(
    try(var.hub_vnet.ddos_protection_plan_id, null),
    try(var.ddos_protection_plan.existing_plan_id, null),
    try(module.ddos_protection_plan[0].id, null)
  ), null)
  hub_ddos_protection_plan_id = coalesce(try(var.ddos_protection_plan.enable_for_hub_vnet, null), true) ? local.ddos_protection_plan_id : null
}

module "ddos_protection_plan" {
  source = "../../modules/terraform-azurerm-compeer-ddos-protection-plan"
  count  = local.ddos_protection_plan_enabled && try(var.ddos_protection_plan.existing_plan_id, null) == null ? 1 : 0

  name                = coalesce(try(var.ddos_protection_plan.name, null), "${var.hub_vnet.name}-ddos")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.tags.tags
}

module "hub_vnet" {
  source = "../../modules/terraform-azurerm-compeer-virtual-network"

  name                           = var.hub_vnet.name
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  address_space                  = var.hub_vnet.address_space
  dns_servers                    = try(var.hub_vnet.dns_servers, null)
  bgp_community                  = try(var.hub_vnet.bgp_community, null)
  edge_zone                      = try(var.hub_vnet.edge_zone, null)
  flow_timeout_in_minutes        = try(var.hub_vnet.flow_timeout_in_minutes, null)
  private_endpoint_vnet_policies = try(var.hub_vnet.private_endpoint_vnet_policies, null)
  ddos_protection_plan_id        = local.hub_ddos_protection_plan_id
  enable_ddos_protection_plan    = try(var.hub_vnet.enable_ddos_protection_plan, true)
  subnets                        = var.hub_vnet.subnets
  encryption                     = try(var.hub_vnet.encryption, null)
  ip_address_pools               = try(var.hub_vnet.ip_address_pools, {})
  timeouts                       = try(var.hub_vnet.timeouts, {})
  tags                           = module.tags.tags
}

module "network_security_groups" {
  source   = "../../modules/terraform-azurerm-compeer-network-security-group"
  for_each = var.network_security_groups

  name                = each.value.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  security_rules = {
    for name, rule in try(each.value.rules, {}) : name => {
      name                                       = name
      description                                = try(rule.description, null)
      protocol                                   = rule.protocol
      source_port_range                          = try(rule.source_port_range, null)
      source_port_ranges                         = try(rule.source_port_ranges, null)
      destination_port_range                     = try(rule.destination_port_range, null)
      destination_port_ranges                    = try(rule.destination_port_ranges, null)
      source_address_prefix                      = try(rule.source_address_prefix, null)
      source_address_prefixes                    = try(rule.source_address_prefixes, null)
      source_application_security_group_ids      = try(rule.source_application_security_group_ids, null)
      destination_address_prefix                 = try(rule.destination_address_prefix, null)
      destination_address_prefixes               = try(rule.destination_address_prefixes, null)
      destination_application_security_group_ids = try(rule.destination_application_security_group_ids, null)
      access                                     = rule.access
      priority                                   = rule.priority
      direction                                  = rule.direction
    }
  }
  tags = module.tags.tags
}

module "subnet_nsg_associations" {
  source   = "../../modules/terraform-azurerm-compeer-nsg-subnet-association"
  for_each = var.subnet_nsg_associations

  subnet_id                 = module.hub_vnet.subnet_ids[each.value.subnet_key]
  network_security_group_id = module.network_security_groups[each.value.nsg_key].id
}

module "route_tables" {
  source   = "../../modules/terraform-azurerm-compeer-route-table"
  for_each = var.route_tables

  name                          = each.value.name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  routes                        = each.value.routes
  tags                          = module.tags.tags
}

module "subnet_route_table_associations" {
  source   = "../../modules/terraform-azurerm-compeer-subnet-route-table-association"
  for_each = var.subnet_route_table_associations

  subnet_id      = module.hub_vnet.subnet_ids[each.value.subnet_key]
  route_table_id = module.route_tables[each.value.route_table_key].id
}

module "public_ips" {
  source   = "../../modules/terraform-azurerm-compeer-public-ip"
  for_each = var.public_ips

  name                    = each.value.name
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  allocation_method       = each.value.allocation_method
  sku                     = each.value.sku
  sku_tier                = each.value.sku_tier
  ip_version              = each.value.ip_version
  edge_zone               = try(each.value.edge_zone, null)
  domain_name_label       = try(each.value.domain_name_label, null)
  domain_name_label_scope = try(each.value.domain_name_label_scope, null)
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  public_ip_prefix_id     = try(each.value.public_ip_prefix_id, null)
  reverse_fqdn            = try(each.value.reverse_fqdn, null)
  ddos_protection_mode    = try(each.value.ddos_protection_mode, null)
  ddos_protection_plan_id = try(each.value.ddos_protection_plan_id, null)
  ip_tags                 = try(each.value.ip_tags, {})
  zones                   = each.value.zones
  timeouts                = try(each.value.timeouts, {})
  tags                    = module.tags.tags
}

module "route_server_public_ips" {
  source   = "../../modules/terraform-azurerm-compeer-public-ip"
  for_each = var.route_server_public_ips

  name                    = each.value.name
  resource_group_name     = coalesce(try(each.value.resource_group_name, null), module.resource_group.name)
  location                = coalesce(try(each.value.location, null), module.resource_group.location)
  allocation_method       = try(each.value.allocation_method, "Static")
  sku                     = try(each.value.sku, "Standard")
  sku_tier                = try(each.value.sku_tier, "Regional")
  ip_version              = try(each.value.ip_version, "IPv4")
  edge_zone               = try(each.value.edge_zone, null)
  domain_name_label       = try(each.value.domain_name_label, null)
  domain_name_label_scope = try(each.value.domain_name_label_scope, null)
  idle_timeout_in_minutes = try(each.value.idle_timeout_in_minutes, 4)
  public_ip_prefix_id     = try(each.value.public_ip_prefix_id, null)
  reverse_fqdn            = try(each.value.reverse_fqdn, null)
  ddos_protection_mode    = try(each.value.ddos_protection_mode, null)
  ddos_protection_plan_id = try(each.value.ddos_protection_plan_id, null)
  ip_tags                 = try(each.value.ip_tags, {})
  zones                   = try(each.value.zones, [])
  timeouts                = try(each.value.timeouts, {})
  tags                    = merge(module.tags.tags, try(each.value.tags, {}))
}

module "route_server" {
  source = "../../modules/terraform-azurerm-compeer-route-server"

  route_servers = {
    for key, route_server in var.route_servers : key => {
      name                             = route_server.name
      resource_group_name              = coalesce(try(route_server.resource_group_name, null), module.resource_group.name)
      location                         = coalesce(try(route_server.location, null), module.resource_group.location)
      sku                              = try(route_server.sku, "Standard")
      subnet_id                        = coalesce(try(route_server.subnet_id, null), try(module.hub_vnet.subnet_ids[route_server.subnet_key], null))
      public_ip_address_id             = coalesce(try(route_server.public_ip_address_id, null), try(module.route_server_public_ips[route_server.public_ip_key].id, null), try(module.public_ips[route_server.public_ip_key].id, null))
      branch_to_branch_traffic_enabled = try(route_server.branch_to_branch_traffic_enabled, true)
      timeouts                         = try(route_server.timeouts, {})
      bgp_connections                  = try(route_server.bgp_connections, {})
      tags                             = merge(module.tags.tags, try(route_server.tags, {}))
    }
  }
}

module "private_dns_zones" {
  source = "../../modules/terraform-azurerm-compeer-private-dns-zone"

  zones = {
    for key, zone in var.private_dns_zones : key => {
      name                = zone.name
      resource_group_name = coalesce(try(zone.resource_group_name, null), module.resource_group.name)
      tags                = module.tags.tags
    }
  }
  tags = module.tags.tags
}

module "private_dns_hub_links" {
  source = "../../modules/terraform-azurerm-compeer-private-dns-vnet-link"

  links = {
    for key, zone in var.private_dns_zones : key => {
      name                  = "lnk-${key}-${var.environment}-hub"
      resource_group_name   = coalesce(try(zone.resource_group_name, null), module.resource_group.name)
      private_dns_zone_name = module.private_dns_zones.names[key]
      virtual_network_id    = module.hub_vnet.id
      registration_enabled  = zone.registration_enabled
      tags                  = module.tags.tags
    }
    if zone.link_to_hub
  }
  tags = module.tags.tags
}

module "private_dns_resolver" {
  source = "../../modules/terraform-azurerm-compeer-private-dns-resolver"
  count  = coalesce(try(var.private_dns_resolver.enabled, null), false) ? 1 : 0

  name                = coalesce(try(var.private_dns_resolver.name, null), "${var.hub_vnet.name}-pdnsr")
  resource_group_name = coalesce(try(var.private_dns_resolver.resource_group_name, null), module.resource_group.name)
  location            = coalesce(try(var.private_dns_resolver.location, null), module.resource_group.location)
  virtual_network_id  = coalesce(try(var.private_dns_resolver.virtual_network_id, null), module.hub_vnet.id)
  inbound_endpoints = {
    for key, endpoint in try(var.private_dns_resolver.inbound_endpoints, {}) : key => {
      subnet_id                    = coalesce(try(endpoint.subnet_id, null), try(module.hub_vnet.subnet_ids[endpoint.subnet_key], null))
      private_ip_allocation_method = try(endpoint.private_ip_allocation_method, "Dynamic")
      private_ip_address           = try(endpoint.private_ip_address, null)
      tags                         = merge(module.tags.tags, try(endpoint.tags, {}))
    }
  }
  outbound_endpoints = {
    for key, endpoint in try(var.private_dns_resolver.outbound_endpoints, {}) : key => {
      subnet_id = coalesce(try(endpoint.subnet_id, null), try(module.hub_vnet.subnet_ids[endpoint.subnet_key], null))
      tags      = merge(module.tags.tags, try(endpoint.tags, {}))
    }
  }
  forwarding_rulesets = try(var.private_dns_resolver.forwarding_rulesets, {})
  forwarding_rules    = try(var.private_dns_resolver.forwarding_rules, {})
  forwarding_ruleset_vnet_links = {
    for key, link in try(var.private_dns_resolver.forwarding_ruleset_vnet_links, {}) : key => {
      ruleset_key        = link.ruleset_key
      virtual_network_id = coalesce(try(link.virtual_network_id, null), module.hub_vnet.id)
      metadata           = try(link.metadata, null)
    }
  }
  tags = module.tags.tags
}

module "bastion" {
  source = "../../modules/terraform-azurerm-compeer-bastion-host"
  count  = coalesce(try(var.bastion.enabled, null), false) ? 1 : 0

  name                      = coalesce(try(var.bastion.name, null), "${var.hub_vnet.name}-bas")
  resource_group_name       = coalesce(try(var.bastion.resource_group_name, null), module.resource_group.name)
  location                  = coalesce(try(var.bastion.location, null), module.resource_group.location)
  bastion_subnet_id         = coalesce(try(var.bastion.subnet_id, null), try(module.hub_vnet.subnet_ids[var.bastion.subnet_key], null), try(module.hub_vnet.subnet_ids["AzureBastionSubnet"], null))
  sku                       = try(var.bastion.sku, "Standard")
  copy_paste_enabled        = try(var.bastion.copy_paste_enabled, true)
  file_copy_enabled         = try(var.bastion.file_copy_enabled, false)
  ip_connect_enabled        = try(var.bastion.ip_connect_enabled, false)
  kerberos_enabled          = try(var.bastion.kerberos_enabled, false)
  session_recording_enabled = try(var.bastion.session_recording_enabled, false)
  shareable_link_enabled    = try(var.bastion.shareable_link_enabled, false)
  tunneling_enabled         = try(var.bastion.tunneling_enabled, true)
  scale_units               = try(var.bastion.scale_units, 2)
  public_ip_zones           = try(var.bastion.public_ip_zones, [])
  public_ip_id              = try(var.bastion.public_ip_id, null)
  public_ip                 = try(var.bastion.public_ip, {})
  zones                     = try(var.bastion.zones, null)
  diagnostic_settings       = try(var.bastion.diagnostic_settings, {})
  timeouts                  = try(var.bastion.timeouts, {})
  tags                      = module.tags.tags
}

locals {
  load_balancer_inputs = {
    for key, lb in var.load_balancers : key => merge(lb, {
      frontend_ip_configurations = {
        for frontend_key, frontend in lb.frontend_ip_configurations : frontend_key => {
          subnet_id = try(coalesce(
            try(frontend.subnet_id, null),
            try(module.hub_vnet.subnet_ids[frontend.subnet_key], null)
            ),
            null
          )
          private_ip_address            = try(frontend.private_ip_address, null)
          private_ip_address_allocation = try(frontend.private_ip_address_allocation, null)
          private_ip_address_version    = try(frontend.private_ip_address_version, null)
          public_ip_address_id = try(coalesce(
            try(frontend.public_ip_address_id, null),
            try(module.public_ips[frontend.public_ip_key].id, null)
            ),
            null
          )
          public_ip_prefix_id                                = try(frontend.public_ip_prefix_id, null)
          gateway_load_balancer_frontend_ip_configuration_id = try(frontend.gateway_load_balancer_frontend_ip_configuration_id, null)
          zones                                              = try(frontend.zones, null)
        }
      }
    })
  }

  palo_alto_enabled              = try(var.palo_alto.enabled, false)
  palo_alto_private_ip_addresses = try(var.palo_alto.private_ip_addresses, {})
  palo_alto_subnet_keys = compact([
    try(var.palo_alto.trusted_subnet_key, null),
    try(var.palo_alto.untrusted_subnet_key, null),
    try(var.palo_alto.management_subnet_key, null)
  ])

  virtual_appliance_next_hops = distinct(compact(flatten([
    for table in values(var.route_tables) : [
      for route in values(try(table.routes, {})) : try(route.next_hop_in_ip_address, null)
      if try(route.next_hop_type, null) == "VirtualAppliance"
    ]
  ])))

  undeclared_palo_alto_next_hops = local.palo_alto_enabled ? [
    for ip in local.virtual_appliance_next_hops : ip
    if !contains(values(local.palo_alto_private_ip_addresses), ip)
  ] : []

  missing_palo_alto_subnet_keys = [
    for key in local.palo_alto_subnet_keys : key
    if !contains(keys(var.hub_vnet.subnets), key)
  ]

  dns_resolution_enabled = coalesce(try(var.dns_resolution.enabled, null), false)
  dns_resolution_mode    = coalesce(try(var.dns_resolution.mode, null), "dc-forwarders")
  dns_resolution_server_ips = coalesce(
    try(var.dns_resolution.dns_server_ips, null),
    []
  )

  connectivity_scope_ids = merge(
    {
      resource_group = module.resource_group.id
      hub_vnet       = module.hub_vnet.id
    },
    local.ddos_protection_plan_id == null ? {} : {
      ddos_protection_plan = local.ddos_protection_plan_id
    },
    {
      for key, value in module.network_security_groups : "nsg:${key}" => value.id
    },
    {
      for key, value in module.route_tables : "route_table:${key}" => value.id
    },
    {
      for key, value in module.public_ips : "public_ip:${key}" => value.id
    },
    {
      for key, value in module.route_server_public_ips : "route_server_public_ip:${key}" => value.id
    },
    {
      for key, value in module.route_server.ids : "route_server:${key}" => value
    },
    {
      for key, value in module.load_balancers : "load_balancer:${key}" => value.id
    },
    {
      for key, value in module.private_dns_zones.ids : "private_dns_zone:${key}" => value
    },
    length(module.private_dns_resolver) == 0 ? {} : {
      private_dns_resolver = module.private_dns_resolver[0].id
    },
    length(module.bastion) == 0 ? {} : {
      bastion           = module.bastion[0].id
      bastion_public_ip = module.bastion[0].public_ip_id
    },
    {
      for key, value in azurerm_network_watcher.this : "network_watcher:${key}" => value.id
    },
    {
      for key, value in module.local_network_gateways.ids : "local_network_gateway:${key}" => value
    },
    var.additional_scopes
  )

  role_assignment_inputs = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      scope = coalesce(
        try(assignment.scope, null),
        try(local.connectivity_scope_ids[assignment.scope_key], null)
      )
    })
  }
}

module "load_balancers" {
  source   = "../../modules/terraform-azurerm-compeer-load-balancer"
  for_each = local.load_balancer_inputs

  name                       = each.value.name
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  sku                        = each.value.sku
  sku_tier                   = try(each.value.sku_tier, null)
  edge_zone                  = try(each.value.edge_zone, null)
  frontend_ip_configurations = each.value.frontend_ip_configurations
  backend_address_pools      = each.value.backend_address_pools
  backend_addresses          = try(each.value.backend_addresses, {})
  probes                     = each.value.probes
  rules                      = each.value.rules
  nat_rules                  = try(each.value.nat_rules, {})
  outbound_rules             = try(each.value.outbound_rules, {})
  timeouts                   = try(each.value.timeouts, {})
  tags                       = module.tags.tags
}

resource "azurerm_network_watcher" "this" {
  for_each = var.network_watchers

  name                = each.value.name
  location            = coalesce(try(each.value.location, null), module.resource_group.location)
  resource_group_name = coalesce(try(each.value.resource_group_name, null), module.resource_group.name)
  tags                = merge(module.tags.tags, try(each.value.tags, {}))
}

module "local_network_gateways" {
  source = "../../modules/terraform-azurerm-compeer-local-network-gateway"

  local_network_gateways = {
    for key, gateway in var.local_network_gateways : key => {
      name                = gateway.name
      resource_group_name = coalesce(try(gateway.resource_group_name, null), module.resource_group.name)
      location            = coalesce(try(gateway.location, null), module.resource_group.location)
      gateway_address     = gateway.gateway_address
      address_space       = gateway.address_space
      bgp_settings        = try(gateway.bgp_settings, null)
      timeouts            = try(gateway.timeouts, {})
      tags                = merge(module.tags.tags, try(gateway.tags, {}))
    }
  }
}

module "network_watcher_flow_logs" {
  source = "../../modules/terraform-azurerm-compeer-network-watcher-flow-logs"

  flow_logs = {
    for key, flow_log in var.network_watcher_flow_logs : key => {
      name                      = flow_log.name
      network_watcher_name      = coalesce(try(flow_log.network_watcher_name, null), try(azurerm_network_watcher.this[flow_log.network_watcher_key].name, null))
      resource_group_name       = coalesce(try(flow_log.resource_group_name, null), try(azurerm_network_watcher.this[flow_log.network_watcher_key].resource_group_name, null), module.resource_group.name)
      network_security_group_id = coalesce(try(flow_log.network_security_group_id, null), try(module.network_security_groups[flow_log.network_security_group_key].id, null))
      storage_account_id        = flow_log.storage_account_id
      enabled                   = try(flow_log.enabled, true)
      retention_policy          = try(flow_log.retention_policy, {})
      traffic_analytics         = try(flow_log.traffic_analytics, null)
      timeouts                  = try(flow_log.timeouts, {})
    }
  }
}

resource "terraform_data" "palo_alto_route_contract" {
  input = {
    enabled                     = local.palo_alto_enabled
    deployment_model            = try(var.palo_alto.deployment_model, "external")
    target_sku                  = try(var.palo_alto.target_sku, null)
    ha_mode                     = try(var.palo_alto.ha_mode, null)
    license_model               = try(var.palo_alto.license_model, null)
    private_ip_addresses        = local.palo_alto_private_ip_addresses
    virtual_appliance_next_hops = local.virtual_appliance_next_hops
    subnet_keys                 = local.palo_alto_subnet_keys
    panorama_managed            = try(var.palo_alto.panorama_managed, true)
    bootstrap                   = try(var.palo_alto.bootstrap, {})
    management                  = try(var.palo_alto.management, {})
    notes                       = try(var.palo_alto.notes, null)
  }

  lifecycle {
    precondition {
      condition     = !local.palo_alto_enabled || length(local.palo_alto_private_ip_addresses) > 0
      error_message = "When Palo Alto posture is enabled, set at least one IP in var.palo_alto.private_ip_addresses."
    }

    precondition {
      condition     = !local.palo_alto_enabled || length(local.virtual_appliance_next_hops) > 0
      error_message = "When Palo Alto posture is enabled, configure at least one VirtualAppliance route."
    }

    precondition {
      condition     = length(local.undeclared_palo_alto_next_hops) == 0
      error_message = "Every VirtualAppliance route next hop must be declared in var.palo_alto.private_ip_addresses when Palo Alto posture is enabled."
    }

    precondition {
      condition     = length(local.missing_palo_alto_subnet_keys) == 0
      error_message = "Palo Alto subnet keys must exist in var.hub_vnet.subnets."
    }
  }
}

resource "terraform_data" "dns_resolution_contract" {
  input = {
    enabled                  = local.dns_resolution_enabled
    mode                     = local.dns_resolution_mode
    private_resolver_enabled = coalesce(try(var.dns_resolution.private_resolver_enabled, null), false)
    dns_server_ips           = local.dns_resolution_server_ips
    hub_vnet_dns_servers     = try(var.hub_vnet.dns_servers, [])
    notes                    = try(var.dns_resolution.notes, null)
  }

  lifecycle {
    precondition {
      condition = (
        !local.dns_resolution_enabled ||
        local.dns_resolution_mode != "dc-forwarders" ||
        length(local.dns_resolution_server_ips) > 0
      )
      error_message = "When DNS resolution uses dc-forwarders, set at least one DNS server IP."
    }
  }
}

module "role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.role_assignment_inputs
}

resource "azurerm_management_lock" "this" {
  for_each = var.management_locks

  name       = each.value.name
  scope      = coalesce(try(each.value.scope, null), try(local.connectivity_scope_ids[each.value.scope_key], null))
  lock_level = each.value.lock_level
  notes      = try(each.value.notes, null)
}

module "diagnostic_settings" {
  source   = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  for_each = var.diagnostic_settings

  name                       = each.value.name
  target_resource_id         = coalesce(try(each.value.target_resource_id, null), try(local.connectivity_scope_ids[each.value.target_key], null))
  log_analytics_workspace_id = each.value.log_analytics_workspace_id
  storage_account_id         = try(each.value.storage_account_id, null)
  eventhub_authorization_rule_id = try(
    each.value.eventhub_authorization_rule_id,
    null
  )
  eventhub_name       = try(each.value.eventhub_name, null)
  partner_solution_id = try(each.value.partner_solution_id, null)
  logs                = each.value.logs
  metrics             = each.value.metrics
}
