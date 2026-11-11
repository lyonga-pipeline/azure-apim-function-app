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
    remove_route_keys          = optional(map(set(string)), {})
    management_subnet_key      = optional(string, "prod-mgmt-subnet")
    management_route_table_key = optional(string)     # Existing association to retain; never a new matrix role.
    change_reference           = optional(string, "") # Optional audit annotation; not a deployment gate.
    ownership_reviewed         = optional(bool, false)
    firewall_path_ready        = optional(bool, false)
    management_oob_confirmed   = optional(bool, false) # Compatibility name: reviewed management path, NOT permission to detach.
  })
  default = {}
}

locals {
  firewall_routing_active = local.enabled && var.firewall_routing.enabled
  # Exact Hub Route Tables matrix from Azure Resource Deployment v2. Management
  # stays outside this generator. Dan confirmed its table must stay attached;
  # preserve existing routes pending clarification of the listed default route.
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
  firewall_management_table_keys = concat(
    try(var.connectivity.hub_vnet.subnets[var.firewall_routing.management_subnet_key].route_table_key, null) == null ? [] : [var.connectivity.hub_vnet.subnets[var.firewall_routing.management_subnet_key].route_table_key],
    [for a in values(local.firewall_base_associations) : a.route_table_key if a.subnet_key == var.firewall_routing.management_subnet_key]
  )
  firewall_management_table_key = try(one(local.firewall_management_table_keys), null)
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

  # Report the exact failed check instead of masking unrelated input errors in
  # one large try(). These checks retain the existing cutover restrictions.
  firewall_readiness_checks = {
    connectivity_enabled     = local.enabled
    ownership_reviewed       = var.firewall_routing.ownership_reviewed
    firewall_path_ready      = var.firewall_routing.firewall_path_ready
    management_oob_confirmed = var.firewall_routing.management_oob_confirmed
  }
  firewall_binding_checks = merge({
    required_roles     = toset(keys(var.firewall_routing.table_bindings)) == toset(keys(local.firewall_route_matrix))
    unique_table_keys  = length(distinct([for b in values(var.firewall_routing.table_bindings) : b.route_table_key])) == 9
    unique_subnet_keys = length(distinct([for b in values(var.firewall_routing.table_bindings) : b.subnet_key])) == 9
    gateway_subnet     = try(var.firewall_routing.table_bindings.gateway.subnet_key == "GatewaySubnet", false)
    }, merge({}, [for role, b in var.firewall_routing.table_bindings : {
      "${role}.table_key_valid"      = can(regex("^[a-z][a-z0-9_-]*$", b.route_table_key))
      "${role}.subnet_exists"        = try(length(var.connectivity.hub_vnet.subnets[b.subnet_key].address_prefixes) > 0, false)
      "${role}.single_association"   = length([for a in values(local.firewall_base_associations) : a if a.subnet_key == b.subnet_key]) <= 1
      "${role}.name_valid"           = b.name == null ? true : length(trimspace(b.name)) > 0 && !can(regex("(?i)(REPLACE|TODO|PLACEHOLDER)", b.name))
      "${role}.table_name_preserved" = b.name == null || !contains(keys(local.firewall_base_route_tables), b.route_table_key) || try(b.name == local.firewall_base_route_tables[b.route_table_key].name, false)
      "${role}.subnet_role_allowed"  = role == "gateway" || !contains(["GatewaySubnet", "RouteServerSubnet", var.firewall_routing.management_subnet_key], b.subnet_key)
  }]...))
  firewall_route_checks = merge({
    "management.subnet_exists"         = contains(keys(try(var.connectivity.hub_vnet.subnets, {})), var.firewall_routing.management_subnet_key)
    "management.not_reserved_or_bound" = !contains(concat(["GatewaySubnet", "RouteServerSubnet"], keys(local.firewall_subnet_table_keys)), var.firewall_routing.management_subnet_key)
    "management.single_association"    = length(local.firewall_management_table_keys) <= 1
    "management.expected_association" = var.firewall_routing.management_route_table_key == null ? true : try(
      local.firewall_management_table_key == var.firewall_routing.management_route_table_key, false
    )
    "management.dedicated_existing_table" = local.firewall_management_table_key == null ? true : (
      contains(keys(local.firewall_base_route_tables), local.firewall_management_table_key) &&
      !contains([for b in values(local.firewall_bindings) : b.route_table_key], local.firewall_management_table_key)
    )
    "management.bgp_preserved_enabled" = local.firewall_management_table_key == null ? true : try(
      local.firewall_base_route_tables[local.firewall_management_table_key].bgp_route_propagation_enabled == true, false
    )
    }, {
    for role, routes in local.firewall_retained_routes : "${role}.unique_destinations" => length(distinct([for r in values(routes) : r.address_prefix])) == length(routes)
    }, {
    for role in ["gateway", "appgw"] : "${role}.no_default_route" => try(alltrue([
      for r in values(local.firewall_effective_route_tables[var.firewall_routing.table_bindings[role].route_table_key].routes) : r.address_prefix != "0.0.0.0/0"
    ]), false)
    }, {
    for key, names in var.firewall_routing.remove_route_keys : "${key}.removal_keys_exist" => try(
      contains(keys(local.firewall_route_overlays), key) && alltrue([for name in names : contains(keys(local.firewall_base_route_tables[key].routes), name)]), false
    )
  })
}

resource "terraform_data" "firewall_routing_contract" {
  count = var.firewall_routing.enabled ? 1 : 0
  lifecycle {
    precondition {
      condition     = alltrue(values(local.firewall_readiness_checks))
      error_message = "Hub routing readiness not confirmed: ${join(", ", [for check, passed in local.firewall_readiness_checks : check if !passed])}. Confirm these facts before enabling; do not bypass the checks."
    }
    precondition {
      condition     = alltrue(values(local.firewall_binding_checks))
      error_message = "Hub routing binding checks failed: ${join(", ", [for check, passed in local.firewall_binding_checks : check if !passed])}. Use existing table/subnet keys. If table_name_preserved fails, omit name for an existing table; a binding must not rename it."
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
      condition     = alltrue(values(local.firewall_route_checks))
      error_message = "Hub routing safety checks failed: ${join(", ", [for check, passed in local.firewall_route_checks : check if !passed])}. Restore the existing management association in connectivity inputs, preserve its dedicated table and BGP=true, and do not add management to table_bindings. Remove an approved App Gateway/Gateway default through remove_route_keys, not by deleting this precondition."
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
