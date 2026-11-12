# PHASE 2 ROUTING FOLLOW-UP: coordinated Identity static routes + BGP-off cutover.
# This root remains the route-table owner. Do not move these tables into peering.
variable "firewall_routing" {
  description = "Opt-in Identity cutover for existing route-table keys only. Requires reviewed static destinations and a healthy firewall/return path; preserves existing names and VM/VNet configuration."
  type = object({
    enabled                   = optional(bool, false)
    route_table_keys          = optional(set(string), []) # Existing Identity-owned table keys, required when enabled.
    trust_ilb_frontend_ip     = optional(string)
    hub_address_prefixes      = optional(set(string), [])
    remote_address_prefixes   = optional(map(set(string)), {}) # Optional reviewed exceptions, not a spoke inventory.
    remove_route_keys         = optional(map(set(string)), {})
    change_reference          = optional(string, "") # Optional audit annotation; not a deployment gate.
    ownership_reviewed        = optional(bool, false)
    firewall_path_ready       = optional(bool, false)
    static_route_set_reviewed = optional(bool, false)
  })
  default = {}
}

locals {
  identity_firewall_active = local.enabled && var.firewall_routing.enabled
  identity_firewall_keys = toset([for key in var.firewall_routing.route_table_keys : key
    if local.identity_firewall_active && contains(keys(try(var.directory_services.route_tables, {})), key)
  ])
  identity_retained_routes = { for key in local.identity_firewall_keys : key => {
    for name, route in try(var.directory_services.route_tables[key].routes, {}) : name => route
    if !contains(lookup(var.firewall_routing.remove_route_keys, key, []), name)
  } }
  identity_static_prefixes = merge(
    { hub = var.firewall_routing.hub_address_prefixes },
    { for key, prefixes in var.firewall_routing.remote_address_prefixes : "remote-${key}" => prefixes }
  )
  identity_desired_routes = merge({ default = {
    address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = var.firewall_routing.trust_ilb_frontend_ip
    } }, merge({}, [for destination, prefixes in local.identity_static_prefixes : {
      for prefix in prefixes : "inspect-${destination}-${replace(replace(prefix, ".", "-"), "/", "-")}" => {
        address_prefix = prefix, next_hop_type = "VirtualAppliance", next_hop_in_ip_address = var.firewall_routing.trust_ilb_frontend_ip
      }
  }]...))
  identity_firewall_route_overlays = { for key in local.identity_firewall_keys : key => merge(
    try(var.directory_services.route_tables[key], {}), {
      bgp_route_propagation_enabled = false
      routes = merge(local.identity_retained_routes[key], {
        for name, route in local.identity_desired_routes : coalesce(try(one([
          for old_name, old in local.identity_retained_routes[key] : old_name if old.address_prefix == route.address_prefix
        ]), null), name) => route
      })
    }
  ) }
  identity_firewall_effective_route_tables = merge(try(var.directory_services.route_tables, {}), local.identity_firewall_route_overlays)
  identity_reviewed_prefixes               = flatten(values(local.identity_static_prefixes))
}

resource "terraform_data" "firewall_routing_contract" {
  count = var.firewall_routing.enabled ? 1 : 0
  lifecycle {
    precondition {
      condition = (
        local.enabled && var.firewall_routing.ownership_reviewed && var.firewall_routing.firewall_path_ready &&
        var.firewall_routing.static_route_set_reviewed
      )
      error_message = "Identity BGP cutover requires the existing owner, a healthy firewall/return path and a reviewed complete static-route set. Do not disable BGP as an isolated change."
    }
    precondition {
      condition = try(
        length(var.firewall_routing.route_table_keys) > 0 &&
        alltrue([for key in var.firewall_routing.route_table_keys : contains(keys(var.directory_services.route_tables), key)]) &&
        can(cidrnetmask("${var.firewall_routing.trust_ilb_frontend_ip}/32")) &&
        length(var.firewall_routing.hub_address_prefixes) > 0 &&
        anytrue([for prefix in var.firewall_routing.hub_address_prefixes : cidrhost("${var.firewall_routing.trust_ilb_frontend_ip}/${split("/", prefix)[1]}", 0) == cidrhost(prefix, 0)]) &&
        alltrue([for prefixes in values(var.firewall_routing.remote_address_prefixes) : length(prefixes) > 0]) &&
        length(distinct(local.identity_reviewed_prefixes)) == length(local.identity_reviewed_prefixes) &&
        alltrue([for prefix in local.identity_reviewed_prefixes : can(cidrnetmask(prefix)) && cidrhost(prefix, 0) == split("/", prefix)[0] && prefix != "0.0.0.0/0"]), false
      )
      error_message = "Select existing Identity route-table keys and provide the verified Trust ILB IP and canonical hub CIDRs. remote_address_prefixes may be empty for Hub-only peering with default firewall routing; supplied exceptions must contain reviewed, nonempty canonical IPv4 prefixes, not guessed DNS-server networks."
    }
    precondition {
      condition = try(
        alltrue([for key, routes in local.identity_retained_routes : length(distinct([for r in values(routes) : r.address_prefix])) == length(routes)]) &&
        alltrue([for key, names in var.firewall_routing.remove_route_keys : contains(var.firewall_routing.route_table_keys, key) && alltrue([for name in names : contains(keys(var.directory_services.route_tables[key].routes), name)])]), false
      )
      error_message = "Reconcile duplicate destinations and explicitly inventory any temporary bypass route names to remove from selected Identity tables."
    }
  }
}

output "firewall_routing_review" {
  description = "Effective static routes and BGP=false for selected existing Identity tables; null while disabled. Not proof of live hybrid connectivity."
  value = !local.identity_firewall_active ? null : {
    for key in local.identity_firewall_keys : key => local.route_tables[key]
  }
}
