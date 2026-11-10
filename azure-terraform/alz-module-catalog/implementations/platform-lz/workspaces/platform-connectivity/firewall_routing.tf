# PHASE 2 ROUTING FOLLOW-UP: Dan's deferred firewall cutover, opt-in and owned here.
# Extend the existing inline route-table owner; never add standalone azurerm_route.
variable "firewall_routing" {
  description = "Reviewed hub routing cutover. Disabled preserves existing inputs. Bind roles to current Terraform keys; never guess deployed names or the Trust ILB frontend."
  type = object({
    enabled                = optional(bool, false)
    trust_ilb_frontend_ip  = optional(string)
    spoke_address_prefixes = optional(map(set(string)), {})
    table_bindings = optional(map(object({
      route_table_key = string
      subnet_key      = string
      name            = optional(string)
    })), {})
    remove_route_keys        = optional(map(set(string)), {})
    management_subnet_key    = optional(string, "prod-mgmt-subnet")
    change_reference         = optional(string, "") # Optional audit annotation; not a deployment gate.
    ownership_reviewed       = optional(bool, false)
    firewall_path_ready      = optional(bool, false)
    management_oob_confirmed = optional(bool, false)
  })
  default = {}
}

locals {
  firewall_routing_active = local.enabled && var.firewall_routing.enabled
  # Exact Hub Route Tables matrix from Azure Resource Deployment v2. Management
  # is excluded: its route list conflicts with the explicit out-of-band note.
  # The three fw_* roles generate blackholes only, never the common spoke/ILB
  # routes. They stay in this Hub owner, not the Palo Alto VM/NIC workspace.
  firewall_route_matrix = {
    gateway    = { inspect = ["sdwan_lan", "shared", "appgw", "cftagent"], drop = ["fw_untrust"], spokes = true, default = false, drop_internet = false, drop_hub = false, bgp = true }
    sdwan_lan  = { inspect = ["shared", "appgw", "cftagent"], drop = ["fw_untrust"], spokes = true, default = true, drop_internet = false, drop_hub = false, bgp = false }
    sdwan_wan  = { inspect = [], drop = ["fw_untrust", "fw_partner"], spokes = false, default = false, drop_internet = false, drop_hub = false, bgp = false }
    shared     = { inspect = ["sdwan_lan", "appgw", "cftagent"], drop = ["fw_untrust", "fw_partner"], spokes = true, default = true, drop_internet = false, drop_hub = false, bgp = false }
    appgw      = { inspect = ["sdwan_lan", "shared", "cftagent"], drop = ["fw_untrust", "fw_partner"], spokes = true, default = false, drop_internet = false, drop_hub = false, bgp = false }
    cftagent   = { inspect = ["sdwan_lan", "shared", "appgw"], drop = ["fw_untrust", "fw_partner"], spokes = true, default = true, drop_internet = false, drop_hub = false, bgp = false }
    fw_trust   = { inspect = [], drop = ["fw_untrust", "fw_partner"], spokes = false, default = false, drop_internet = true, drop_hub = false, bgp = true }
    fw_untrust = { inspect = [], drop = [], spokes = false, default = false, drop_internet = false, drop_hub = true, bgp = false }
    fw_partner = { inspect = [], drop = ["fw_untrust", "fw_trust"], spokes = false, default = false, drop_internet = true, drop_hub = false, bgp = true }
  }
  firewall_bindings          = { for role, binding in var.firewall_routing.table_bindings : role => binding if local.firewall_routing_active && contains(keys(local.firewall_route_matrix), role) }
  firewall_role_prefixes     = { for role, binding in local.firewall_bindings : role => try(var.connectivity.hub_vnet.subnets[binding.subnet_key].address_prefixes, []) }
  firewall_base_route_tables = try(var.connectivity.route_tables, {})
  firewall_retained_routes = { for role, binding in local.firewall_bindings : role => {
    for name, route in try(local.firewall_base_route_tables[binding.route_table_key].routes, {}) : name => route
    if !contains(lookup(var.firewall_routing.remove_route_keys, binding.route_table_key, []), name)
  } }
  firewall_spoke_routes = merge({}, [for spoke, prefixes in var.firewall_routing.spoke_address_prefixes : {
    for prefix in prefixes : "inspect-spoke-${spoke}-${replace(replace(prefix, ".", "-"), "/", "-")}" => {
      address_prefix = prefix, next_hop_type = "VirtualAppliance", next_hop_in_ip_address = var.firewall_routing.trust_ilb_frontend_ip
    }
  }]...)
  firewall_desired_routes = { for role, binding in local.firewall_bindings : role => merge(
    merge({}, [for destination in local.firewall_route_matrix[role].inspect : {
      for prefix in lookup(local.firewall_role_prefixes, destination, []) : "inspect-${destination}-${replace(replace(prefix, ".", "-"), "/", "-")}" => {
        address_prefix = prefix, next_hop_type = "VirtualAppliance", next_hop_in_ip_address = var.firewall_routing.trust_ilb_frontend_ip
      }
    }]...),
    merge({}, [for destination in local.firewall_route_matrix[role].drop : {
      for prefix in lookup(local.firewall_role_prefixes, destination, []) : "drop-${destination}-${replace(replace(prefix, ".", "-"), "/", "-")}" => {
        address_prefix = prefix, next_hop_type = "None", next_hop_in_ip_address = null
      }
    }]...),
    local.firewall_route_matrix[role].spokes ? local.firewall_spoke_routes : {},
    local.firewall_route_matrix[role].default ? { default = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = var.firewall_routing.trust_ilb_frontend_ip } } : {},
    # Internet is NOT a supported UDR service tag. A default drop is the explicit
    # representation here; more-specific routes still win. Review before cutover.
    local.firewall_route_matrix[role].drop_internet ? { drop-internet = { address_prefix = "0.0.0.0/0", next_hop_type = "None", next_hop_in_ip_address = null } } : {},
    local.firewall_route_matrix[role].drop_hub ? { for prefix in try(var.connectivity.hub_vnet.address_space, []) : "drop-hub-${replace(replace(prefix, ".", "-"), "/", "-")}" => {
      address_prefix = prefix, next_hop_type = "None", next_hop_in_ip_address = null
    } } : {}
  ) }
  # Reuse an existing inline route NAME when its destination already exists.
  # Required routes replace their temporary next hop in-place; unrelated routes
  # survive unless named explicitly in the reviewed removal list.
  firewall_route_overlays = { for role, binding in local.firewall_bindings : binding.route_table_key => {
    name                          = contains(keys(local.firewall_base_route_tables), binding.route_table_key) ? try(local.firewall_base_route_tables[binding.route_table_key].name, null) : binding.name
    bgp_route_propagation_enabled = local.firewall_route_matrix[role].bgp
    routes = merge(local.firewall_retained_routes[role], {
      for name, route in local.firewall_desired_routes[role] : coalesce(try(one([
        for old_name, old in local.firewall_retained_routes[role] : old_name if old.address_prefix == route.address_prefix
      ]), null), name) => route
    })
  } }
  firewall_effective_route_tables = merge(local.firewall_base_route_tables, local.firewall_route_overlays)
  firewall_subnet_table_keys      = { for role, binding in local.firewall_bindings : binding.subnet_key => binding.route_table_key }
  firewall_base_associations      = try(var.connectivity.subnet_route_table_associations, {})
  firewall_effective_associations = { for key, association in local.firewall_base_associations : key => merge(association,
    contains(keys(local.firewall_subnet_table_keys), association.subnet_key) ? { route_table_key = local.firewall_subnet_table_keys[association.subnet_key] } : {}
  ) }
  firewall_effective_hub_vnet = merge(try(var.connectivity.hub_vnet, {}), { subnets = {
    for key, subnet in try(var.connectivity.hub_vnet.subnets, {}) : key => merge(subnet,
      contains(keys(local.firewall_subnet_table_keys), key) ? {
        # An existing explicit association keeps its key/address; do not add a
        # second association for that same subnet through the inline shortcut.
        route_table_key = length([for a in values(local.firewall_base_associations) : a if a.subnet_key == key]) > 0 ? null : local.firewall_subnet_table_keys[key]
      } : {}
    )
  } })
  firewall_checked_prefixes = local.firewall_routing_active ? concat(
    try(var.connectivity.hub_vnet.address_space, []), flatten(values(var.firewall_routing.spoke_address_prefixes))
  ) : []
  firewall_prefix_ranges = { for prefix in toset(local.firewall_checked_prefixes) : prefix => {
    first = try(sum([for i, octet in split(".", cidrhost(prefix, 0)) : parseint(octet, 10) * pow(256, 3 - i)]), -1)
    last  = try(sum([for i, octet in split(".", cidrhost(prefix, -1)) : parseint(octet, 10) * pow(256, 3 - i)]), -1)
  } }
}

resource "terraform_data" "firewall_routing_contract" {
  count = var.firewall_routing.enabled ? 1 : 0
  lifecycle {
    precondition {
      condition = (
        local.enabled && var.firewall_routing.ownership_reviewed && var.firewall_routing.firewall_path_ready &&
        var.firewall_routing.management_oob_confirmed
      )
      error_message = "Hub routing cutover requires the existing owner, reviewed ownership/workaround inventory, a healthy firewall/return path and approved out-of-band management."
    }
    precondition {
      condition = try(
        toset(keys(var.firewall_routing.table_bindings)) == toset(keys(local.firewall_route_matrix)) &&
        length(distinct([for b in values(var.firewall_routing.table_bindings) : b.route_table_key])) == 9 &&
        length(distinct([for b in values(var.firewall_routing.table_bindings) : b.subnet_key])) == 9 &&
        alltrue([for b in values(var.firewall_routing.table_bindings) :
          can(regex("^[a-z][a-z0-9_-]*$", b.route_table_key)) && contains(keys(var.connectivity.hub_vnet.subnets), b.subnet_key) &&
          length(var.connectivity.hub_vnet.subnets[b.subnet_key].address_prefixes) > 0 &&
          length([for a in values(local.firewall_base_associations) : a if a.subnet_key == b.subnet_key]) <= 1 &&
          (b.name == null ? true : length(trimspace(b.name)) > 0 && !can(regex("(?i)(REPLACE|TODO|PLACEHOLDER)", b.name))) &&
          (b.name == null || !contains(keys(local.firewall_base_route_tables), b.route_table_key) || try(b.name == local.firewall_base_route_tables[b.route_table_key].name, false))
        ]) && var.firewall_routing.table_bindings.gateway.subnet_key == "GatewaySubnet" &&
        alltrue([for role, b in var.firewall_routing.table_bindings : role == "gateway" || !contains(["GatewaySubnet", "RouteServerSubnet", var.firewall_routing.management_subnet_key], b.subnet_key)]), false
      )
      error_message = "Bind exactly the nine documented non-management roles to unique existing subnet/table keys. Preserve existing table names; use name=null for an existing generated name. Gateway must bind GatewaySubnet; management and RouteServerSubnet are excluded."
    }
    precondition {
      condition = try(
        can(cidrnetmask("${var.firewall_routing.trust_ilb_frontend_ip}/32")) &&
        anytrue([for prefix in local.firewall_role_prefixes.fw_trust : cidrhost("${var.firewall_routing.trust_ilb_frontend_ip}/${split("/", prefix)[1]}", 0) == cidrhost(prefix, 0)]) &&
        length(var.firewall_routing.spoke_address_prefixes) > 0 &&
        alltrue([for prefixes in values(var.firewall_routing.spoke_address_prefixes) : length(prefixes) > 0]) &&
        alltrue([for prefix in local.firewall_checked_prefixes : can(cidrnetmask(prefix)) && cidrhost(prefix, 0) == split("/", prefix)[0]]) &&
        alltrue(flatten([for i, prefix in local.firewall_checked_prefixes : [for j, other in local.firewall_checked_prefixes : i == j || local.firewall_prefix_ranges[prefix].last < local.firewall_prefix_ranges[other].first || local.firewall_prefix_ranges[other].last < local.firewall_prefix_ranges[prefix].first]])), false
      )
      error_message = "Supply the verified Trust ILB IPv4 frontend inside the trust subnet, plus complete, canonical, non-overlapping deployed hub/spoke IPv4 CIDRs. No guessed next hop or placeholder is accepted when enabled."
    }
    precondition {
      condition = try(
        contains(keys(var.connectivity.hub_vnet.subnets), var.firewall_routing.management_subnet_key) &&
        !contains(concat(["GatewaySubnet", "RouteServerSubnet"], keys(local.firewall_subnet_table_keys)), var.firewall_routing.management_subnet_key) &&
        try(var.connectivity.hub_vnet.subnets[var.firewall_routing.management_subnet_key].route_table_key, null) == null &&
        alltrue([for a in values(local.firewall_base_associations) : a.subnet_key != var.firewall_routing.management_subnet_key]) &&
        alltrue([for role, routes in local.firewall_retained_routes : length(distinct([for r in values(routes) : r.address_prefix])) == length(routes)]) &&
        alltrue([for role in ["gateway", "appgw"] : alltrue([for r in values(local.firewall_effective_route_tables[var.firewall_routing.table_bindings[role].route_table_key].routes) : r.address_prefix != "0.0.0.0/0"])]) &&
        alltrue([for key, names in var.firewall_routing.remove_route_keys : contains(keys(local.firewall_route_overlays), key) && alltrue([for name in names : contains(keys(local.firewall_base_route_tables[key].routes), name)])]), false
      )
      error_message = "Management must remain out-of-band; reconcile its existing association separately. Remove duplicate/bypass routes explicitly. Gateway and App Gateway cannot retain a default UDR. Removal keys must exist in selected tables."
    }
  }
}

output "firewall_routing_review" {
  description = "Plan review only: effective inline routes/table keys for the opt-in firewall cutover; null while disabled. Does not verify live firewall health."
  value = !local.firewall_routing_active ? null : {
    for role, binding in local.firewall_bindings : role => {
      route_table_key = binding.route_table_key
      subnet_key      = binding.subnet_key
      configuration   = local.firewall_effective_route_tables[binding.route_table_key]
    }
  }
}
