variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "centralus"
}

variable "resource_group_name" {
  type = string
}

variable "hub_vnet_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "enable_telemetry" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_ddos" {
  type    = bool
  default = true
}

variable "enable_vpn_gateway" {
  type    = bool
  default = false
}

variable "vpn_gateway_sku" {
  type    = string
  default = "VpnGw2AZ"
}

variable "app_gateway_subnet_id" {
  type = string
}

variable "app_gateway_backend_ips" {
  type    = set(string)
  default = []
}

variable "app_gateway_public_ip_name" {
  type    = string
  default = null
}

variable "network_watchers" {
  description = "Network Watchers to create when the subscription does not already have the regional watcher managed elsewhere."
  type = map(object({
    name                = string
    resource_group_name = optional(string)
    location            = optional(string)
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "local_network_gateways" {
  description = "On-premises gateways for Phase 2 S2S backup VPN."
  type = map(object({
    name                = string
    resource_group_name = optional(string)
    location            = optional(string)
    gateway_address     = string
    address_space       = list(string)
    bgp_settings = optional(object({
      asn                 = number
      bgp_peering_address = string
      peer_weight         = optional(number)
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "vpn_connections" {
  description = "IPsec backup VPN connections. Shared keys are supplied through vpn_connection_shared_keys using matching map keys."
  type = map(object({
    name                       = string
    resource_group_name        = optional(string)
    location                   = optional(string)
    virtual_network_gateway_id = optional(string)
    local_network_gateway_key  = optional(string)
    local_network_gateway_id   = optional(string)
    bgp_enabled                = optional(bool)
    connection_protocol        = optional(string, "IKEv2")
    connection_mode            = optional(string)
    dpd_timeout_seconds        = optional(number)
    routing_weight             = optional(number, 0)
    ipsec_policy = optional(object({
      dh_group         = string
      ike_encryption   = string
      ike_integrity    = string
      ipsec_encryption = string
      ipsec_integrity  = string
      pfs_group        = string
      sa_datasize      = optional(number)
      sa_lifetime      = optional(number)
    }))
    traffic_selector_policies = optional(map(object({
      local_address_cidrs  = list(string)
      remote_address_cidrs = list(string)
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for connection in values(var.vpn_connections) :
      (try(connection.local_network_gateway_key, null) != null) != (try(connection.local_network_gateway_id, null) != null)
    ])
    error_message = "Each vpn_connections item must set exactly one of local_network_gateway_key or local_network_gateway_id."
  }
}

variable "vpn_connection_shared_keys" {
  description = "Sensitive IPsec shared keys keyed by vpn_connections key."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "route_server_public_ips" {
  description = "Public IPs for Azure Route Server."
  type = map(object({
    name                    = string
    resource_group_name     = optional(string)
    location                = optional(string)
    allocation_method       = optional(string, "Static")
    sku                     = optional(string, "Standard")
    sku_tier                = optional(string, "Regional")
    ip_version              = optional(string, "IPv4")
    domain_name_label       = optional(string)
    idle_timeout_in_minutes = optional(number, 4)
    public_ip_prefix_id     = optional(string)
    reverse_fqdn            = optional(string)
    zones                   = optional(list(string), ["1", "2", "3"])
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "route_servers" {
  description = "Azure Route Servers and optional BGP connections."
  type = map(object({
    name                             = string
    resource_group_name              = optional(string)
    location                         = optional(string)
    sku                              = optional(string, "Standard")
    subnet_id                        = string
    public_ip_key                    = optional(string)
    public_ip_address_id             = optional(string)
    branch_to_branch_traffic_enabled = optional(bool, true)
    bgp_connections = optional(map(object({
      name                 = string
      peer_asn             = number
      peer_ip              = string
      ipv4_route_server_id = optional(string)
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for route_server in values(var.route_servers) :
      (try(route_server.public_ip_key, null) != null) != (try(route_server.public_ip_address_id, null) != null)
    ])
    error_message = "Each route_servers item must set exactly one of public_ip_key or public_ip_address_id."
  }
}

variable "network_watcher_flow_logs" {
  description = "NSG flow logs and traffic analytics."
  type = map(object({
    name                      = string
    network_watcher_key       = optional(string)
    network_watcher_name      = optional(string)
    resource_group_name       = optional(string)
    network_security_group_id = string
    storage_account_id        = string
    enabled                   = optional(bool, true)
    retention_policy = optional(object({
      enabled = optional(bool, true)
      days    = optional(number, 90)
    }), {})
    traffic_analytics = optional(object({
      enabled               = optional(bool, true)
      workspace_id          = string
      workspace_region      = string
      workspace_resource_id = string
      interval_in_minutes   = optional(number, 10)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for flow_log in values(var.network_watcher_flow_logs) :
      try(flow_log.network_watcher_key, null) != null || try(flow_log.network_watcher_name, null) != null
    ])
    error_message = "Each network_watcher_flow_logs item must set network_watcher_key or network_watcher_name."
  }
}

variable "network_connection_monitors" {
  description = "Azure Network Watcher connection monitors."
  type = map(object({
    name                          = string
    location                      = optional(string)
    network_watcher_key           = optional(string)
    network_watcher_id            = optional(string)
    notes                         = optional(string)
    output_workspace_resource_ids = optional(set(string))
    endpoints = map(object({
      name                  = string
      address               = optional(string)
      target_resource_id    = optional(string)
      target_resource_type  = optional(string)
      coverage_level        = optional(string)
      included_ip_addresses = optional(set(string))
      excluded_ip_addresses = optional(set(string))
      filter = optional(object({
        type = optional(string)
        items = optional(map(object({
          type    = optional(string)
          address = optional(string)
        })), {})
      }))
    }))
    test_configurations = map(object({
      name                      = string
      protocol                  = string
      preferred_ip_version      = optional(string)
      test_frequency_in_seconds = optional(number)
      http_configuration = optional(object({
        method                   = optional(string)
        path                     = optional(string)
        port                     = optional(number)
        prefer_https             = optional(bool)
        valid_status_code_ranges = optional(set(string))
        request_headers = optional(map(object({
          name  = string
          value = string
        })), {})
      }))
      icmp_configuration = optional(object({
        trace_route_enabled = optional(bool)
      }))
      tcp_configuration = optional(object({
        port                      = number
        destination_port_behavior = optional(string)
        trace_route_enabled       = optional(bool)
      }))
      success_threshold = optional(object({
        checks_failed_percent = optional(number)
        round_trip_time_ms    = optional(number)
      }))
    }))
    test_groups = map(object({
      name                     = string
      enabled                  = optional(bool, true)
      source_endpoints         = set(string)
      destination_endpoints    = set(string)
      test_configuration_names = set(string)
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for monitor in values(var.network_connection_monitors) :
      (try(monitor.network_watcher_key, null) != null) != (try(monitor.network_watcher_id, null) != null)
    ])
    error_message = "Each network_connection_monitors item must set exactly one of network_watcher_key or network_watcher_id."
  }
}
