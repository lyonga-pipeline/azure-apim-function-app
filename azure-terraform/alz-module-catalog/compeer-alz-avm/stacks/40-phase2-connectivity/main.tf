locals { tags = merge({ ManagedBy = "Terraform", IaCSource = "AVM+CompeerHCP+Native", Phase = "2" }, var.tags) }

module "ddos" {
  count               = var.enable_ddos ? 1 : 0
  source              = "Azure/avm-res-network-ddosprotectionplan/azurerm"
  version             = "0.3.0"
  name                = "cmp-cus-ddos-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  lock                = { kind = "CanNotDelete" }
  tags                = local.tags
  enable_telemetry    = var.enable_telemetry
}

# NET-20: second vnetgateway pattern instance for S2S backup.
module "vpn_gateway" {
  count   = var.enable_vpn_gateway ? 1 : 0
  source  = "Azure/avm-ptn-vnetgateway/azurerm"
  version = "0.10.3"

  location  = var.location
  name      = "cmp-cus-vpngw"
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  type                              = "Vpn"
  sku                               = var.vpn_gateway_sku
  subnet_creation_enabled           = false
  virtual_network_gateway_subnet_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${basename(var.hub_vnet_id)}/subnets/GatewaySubnet"
  virtual_network_id                = var.hub_vnet_id
  tags                              = local.tags
  enable_telemetry                  = var.enable_telemetry
}

resource "azurerm_network_watcher" "this" {
  for_each = var.network_watchers

  name                = each.value.name
  location            = coalesce(try(each.value.location, null), var.location)
  resource_group_name = coalesce(try(each.value.resource_group_name, null), var.resource_group_name)
  tags                = merge(local.tags, try(each.value.tags, {}))
}

module "local_network_gateway" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-local-network-gateway/azurerm"
  version = "1.0.0"

  local_network_gateways = {
    for key, gateway in var.local_network_gateways : key => {
      name                = gateway.name
      resource_group_name = coalesce(try(gateway.resource_group_name, null), var.resource_group_name)
      location            = coalesce(try(gateway.location, null), var.location)
      gateway_address     = gateway.gateway_address
      address_space       = gateway.address_space
      bgp_settings        = try(gateway.bgp_settings, null)
      tags                = merge(local.tags, try(gateway.tags, {}))
    }
  }
}

resource "azurerm_virtual_network_gateway_connection" "vpn" {
  for_each = var.vpn_connections

  name                       = each.value.name
  resource_group_name        = coalesce(try(each.value.resource_group_name, null), var.resource_group_name)
  location                   = coalesce(try(each.value.location, null), var.location)
  type                       = "IPsec"
  virtual_network_gateway_id = coalesce(try(each.value.virtual_network_gateway_id, null), try(module.vpn_gateway[0].resource_id, null))
  local_network_gateway_id   = coalesce(try(each.value.local_network_gateway_id, null), try(module.local_network_gateway.ids[each.value.local_network_gateway_key], null))
  shared_key                 = var.vpn_connection_shared_keys[each.key]
  bgp_enabled                = try(each.value.bgp_enabled, null)
  connection_protocol        = try(each.value.connection_protocol, "IKEv2")
  connection_mode            = try(each.value.connection_mode, null)
  dpd_timeout_seconds        = try(each.value.dpd_timeout_seconds, null)
  routing_weight             = try(each.value.routing_weight, 0)
  tags                       = merge(local.tags, try(each.value.tags, {}))

  dynamic "ipsec_policy" {
    for_each = try(each.value.ipsec_policy, null) == null ? [] : [each.value.ipsec_policy]
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
    for_each = try(each.value.traffic_selector_policies, {})
    content {
      local_address_cidrs  = traffic_selector_policy.value.local_address_cidrs
      remote_address_cidrs = traffic_selector_policy.value.remote_address_cidrs
    }
  }

  lifecycle {
    precondition {
      condition     = try(each.value.virtual_network_gateway_id, null) != null || var.enable_vpn_gateway
      error_message = "Set virtual_network_gateway_id or enable_vpn_gateway for every vpn_connections item."
    }
    precondition {
      condition     = contains(keys(var.vpn_connection_shared_keys), each.key)
      error_message = "vpn_connection_shared_keys must contain a key for every vpn_connections item."
    }
  }
}

module "route_server_public_ip" {
  for_each = var.route_server_public_ips
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-public-ip/azurerm"
  version  = "1.0.0"

  name                    = each.value.name
  resource_group_name     = coalesce(try(each.value.resource_group_name, null), var.resource_group_name)
  location                = coalesce(try(each.value.location, null), var.location)
  allocation_method       = try(each.value.allocation_method, "Static")
  sku                     = try(each.value.sku, "Standard")
  sku_tier                = try(each.value.sku_tier, "Regional")
  ip_version              = try(each.value.ip_version, "IPv4")
  domain_name_label       = try(each.value.domain_name_label, null)
  idle_timeout_in_minutes = try(each.value.idle_timeout_in_minutes, 4)
  public_ip_prefix_id     = try(each.value.public_ip_prefix_id, null)
  reverse_fqdn            = try(each.value.reverse_fqdn, null)
  zones                   = try(each.value.zones, ["1", "2", "3"])
  tags                    = merge(local.tags, try(each.value.tags, {}))
}

module "route_server" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-route-server/azurerm"
  version = "1.0.0"

  route_servers = {
    for key, route_server in var.route_servers : key => {
      name                             = route_server.name
      resource_group_name              = coalesce(try(route_server.resource_group_name, null), var.resource_group_name)
      location                         = coalesce(try(route_server.location, null), var.location)
      sku                              = try(route_server.sku, "Standard")
      subnet_id                        = route_server.subnet_id
      public_ip_address_id             = coalesce(try(route_server.public_ip_address_id, null), try(module.route_server_public_ip[route_server.public_ip_key].id, null))
      branch_to_branch_traffic_enabled = try(route_server.branch_to_branch_traffic_enabled, true)
      bgp_connections                  = try(route_server.bgp_connections, {})
      tags                             = merge(local.tags, try(route_server.tags, {}))
    }
  }
}

module "network_watcher_flow_logs" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-network-watcher-flow-logs/azurerm"
  version = "1.0.0"

  flow_logs = {
    for key, flow_log in var.network_watcher_flow_logs : key => {
      name                      = flow_log.name
      network_watcher_name      = coalesce(try(flow_log.network_watcher_name, null), try(azurerm_network_watcher.this[flow_log.network_watcher_key].name, null))
      resource_group_name       = coalesce(try(flow_log.resource_group_name, null), try(azurerm_network_watcher.this[flow_log.network_watcher_key].resource_group_name, null), var.resource_group_name)
      network_security_group_id = flow_log.network_security_group_id
      storage_account_id        = flow_log.storage_account_id
      enabled                   = try(flow_log.enabled, true)
      retention_policy          = try(flow_log.retention_policy, {})
      traffic_analytics         = try(flow_log.traffic_analytics, null)
    }
  }
}

resource "azurerm_network_connection_monitor" "this" {
  for_each = var.network_connection_monitors

  name                          = each.value.name
  location                      = coalesce(try(each.value.location, null), var.location)
  network_watcher_id            = coalesce(try(each.value.network_watcher_id, null), try(azurerm_network_watcher.this[each.value.network_watcher_key].id, null))
  notes                         = try(each.value.notes, null)
  output_workspace_resource_ids = try(each.value.output_workspace_resource_ids, [var.log_analytics_workspace_id])
  tags                          = merge(local.tags, try(each.value.tags, {}))

  dynamic "endpoint" {
    for_each = each.value.endpoints
    content {
      name                  = endpoint.value.name
      address               = try(endpoint.value.address, null)
      target_resource_id    = try(endpoint.value.target_resource_id, null)
      target_resource_type  = try(endpoint.value.target_resource_type, null)
      coverage_level        = try(endpoint.value.coverage_level, null)
      included_ip_addresses = try(endpoint.value.included_ip_addresses, null)
      excluded_ip_addresses = try(endpoint.value.excluded_ip_addresses, null)

      dynamic "filter" {
        for_each = try(endpoint.value.filter, null) == null ? [] : [endpoint.value.filter]
        content {
          type = try(filter.value.type, null)

          dynamic "item" {
            for_each = try(filter.value.items, {})
            content {
              type    = try(item.value.type, null)
              address = try(item.value.address, null)
            }
          }
        }
      }
    }
  }

  dynamic "test_configuration" {
    for_each = each.value.test_configurations
    content {
      name                      = test_configuration.value.name
      protocol                  = test_configuration.value.protocol
      preferred_ip_version      = try(test_configuration.value.preferred_ip_version, null)
      test_frequency_in_seconds = try(test_configuration.value.test_frequency_in_seconds, null)

      dynamic "http_configuration" {
        for_each = try(test_configuration.value.http_configuration, null) == null ? [] : [test_configuration.value.http_configuration]
        content {
          method                   = try(http_configuration.value.method, null)
          path                     = try(http_configuration.value.path, null)
          port                     = try(http_configuration.value.port, null)
          prefer_https             = try(http_configuration.value.prefer_https, null)
          valid_status_code_ranges = try(http_configuration.value.valid_status_code_ranges, null)

          dynamic "request_header" {
            for_each = try(http_configuration.value.request_headers, {})
            content {
              name  = request_header.value.name
              value = request_header.value.value
            }
          }
        }
      }

      dynamic "icmp_configuration" {
        for_each = try(test_configuration.value.icmp_configuration, null) == null ? [] : [test_configuration.value.icmp_configuration]
        content {
          trace_route_enabled = try(icmp_configuration.value.trace_route_enabled, null)
        }
      }

      dynamic "tcp_configuration" {
        for_each = try(test_configuration.value.tcp_configuration, null) == null ? [] : [test_configuration.value.tcp_configuration]
        content {
          port                      = tcp_configuration.value.port
          destination_port_behavior = try(tcp_configuration.value.destination_port_behavior, null)
          trace_route_enabled       = try(tcp_configuration.value.trace_route_enabled, null)
        }
      }

      dynamic "success_threshold" {
        for_each = try(test_configuration.value.success_threshold, null) == null ? [] : [test_configuration.value.success_threshold]
        content {
          checks_failed_percent = try(success_threshold.value.checks_failed_percent, null)
          round_trip_time_ms    = try(success_threshold.value.round_trip_time_ms, null)
        }
      }
    }
  }

  dynamic "test_group" {
    for_each = each.value.test_groups
    content {
      name                     = test_group.value.name
      enabled                  = try(test_group.value.enabled, true)
      source_endpoints         = test_group.value.source_endpoints
      destination_endpoints    = test_group.value.destination_endpoints
      test_configuration_names = test_group.value.test_configuration_names
    }
  }
}

# WAF policy is Compeer-specific per the component sheet; Application Gateway
# itself is AVM. OWASP 3.2 prevention is the baseline.
resource "azurerm_web_application_firewall_policy" "this" {
  name                = "cmp-cus-appgw-waf"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = local.tags
}

module "application_gateway" {
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "0.5.2"

  name                = "cmp-cus-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name

  gateway_ip_configuration = {
    name      = "gateway-ipconfig"
    subnet_id = var.app_gateway_subnet_id
  }

  frontend_ports = {
    https = { name = "https", port = 443 }
  }

  backend_address_pools = {
    default = {
      name         = "default-pool"
      ip_addresses = var.app_gateway_backend_ips
    }
  }

  backend_http_settings = {
    https = {
      name                                 = "https"
      port                                 = 443
      protocol                             = "Https"
      cookie_based_affinity                = "Disabled"
      request_timeout                      = 30
      dedicated_backend_connection_enabled = false
    }
  }

  http_listeners = {
    https = {
      name               = "https"
      frontend_port_name = "https"
      require_sni        = false
    }
  }

  request_routing_rules = {
    default = {
      name                       = "default"
      rule_type                  = "Basic"
      http_listener_name         = "https"
      backend_address_pool_name  = "default-pool"
      backend_http_settings_name = "https"
      priority                   = 100
    }
  }

  app_gateway_waf_policy_resource_id = azurerm_web_application_firewall_policy.this.id
  autoscale_configuration            = { min_capacity = 2, max_capacity = 10 }
  zones                              = ["1", "2", "3"]
  sku = {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 0
  }

  public_ip_address_configuration = {
    create_public_ip_enabled = true
    public_ip_name           = coalesce(var.app_gateway_public_ip_name, "cmp-cus-appgw-pip")
    allocation_method        = "Static"
    sku                      = "Standard"
    sku_tier                 = "Regional"
    zones                    = ["1", "2", "3"]
  }

  diagnostic_settings = {
    law = { workspace_resource_id = var.log_analytics_workspace_id }
  }

  lock             = { kind = "CanNotDelete" }
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}
