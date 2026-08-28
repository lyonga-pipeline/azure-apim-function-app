variable "subscription_id" {
  type        = string
  description = "Platform connectivity subscription id."
}

variable "location" {
  type        = string
  description = "Azure region for connectivity resources."
}

variable "environment" {
  type        = string
  description = "Environment key, such as np or prod."
}

variable "platform_tags" {
  type = object({
    application         = string
    business_owner      = string
    source_repo         = string
    terraform_workspace = string
    recovery_tier       = string
    cost_center         = string
    data_classification = string
    compliance_boundary = string
    additional_tags     = optional(map(string), {})
  })
}

variable "resource_group" {
  type = object({
    name = string
  })
}

variable "hub_vnet" {
  type = object({
    name                           = string
    address_space                  = list(string)
    dns_servers                    = optional(list(string))
    bgp_community                  = optional(string)
    edge_zone                      = optional(string)
    flow_timeout_in_minutes        = optional(number)
    private_endpoint_vnet_policies = optional(string)
    ddos_protection_plan_id        = optional(string)
    enable_ddos_protection_plan    = optional(bool, true)
    subnets = map(object({
      address_prefixes                              = list(string)
      service_endpoints                             = optional(list(string), [])
      service_endpoint_policy_ids                   = optional(list(string), [])
      default_outbound_access_enabled               = optional(bool)
      private_endpoint_network_policies             = optional(string, "Enabled")
      private_link_service_network_policies_enabled = optional(bool, true)
      sharing_scope                                 = optional(string)
      delegations = optional(map(object({
        name    = string
        actions = optional(list(string), [])
      })), {})
      ip_address_pool = optional(object({
        id                     = string
        number_of_ip_addresses = string
      }))
      timeouts = optional(object({
        create = optional(string)
        update = optional(string)
        read   = optional(string)
        delete = optional(string)
      }), {})
    }))
    encryption = optional(object({
      enforcement = string
    }))
    ip_address_pools = optional(map(object({
      id                     = string
      number_of_ip_addresses = string
    })), {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  })
}

variable "ddos_protection_plan" {
  type = object({
    enabled             = optional(bool, false)
    name                = optional(string)
    existing_plan_id    = optional(string)
    enable_for_hub_vnet = optional(bool, true)
  })
  description = "Optional DDoS Protection Plan for the hub VNet. Set existing_plan_id to attach a shared plan instead of creating one."
  default     = {}
}

variable "palo_alto" {
  type = object({
    enabled               = optional(bool, false)
    deployment_model      = optional(string, "external")
    target_sku            = optional(string)
    ha_mode               = optional(string)
    license_model         = optional(string)
    private_ip_addresses  = optional(map(string), {})
    trusted_subnet_key    = optional(string)
    untrusted_subnet_key  = optional(string)
    management_subnet_key = optional(string)
    panorama_managed      = optional(bool, true)
    bootstrap = optional(object({
      enabled              = optional(bool, false)
      storage_account_name = optional(string)
      container_name       = optional(string)
      config_repository    = optional(string)
    }), {})
    management = optional(object({
      platform  = optional(string)
      reference = optional(string)
    }), {})
    notes = optional(string)
  })
  description = "Palo Alto network virtual appliance posture and route contract. This does not deploy paid VM-Series resources by default; it validates route intent when enabled."
  default     = {}

  validation {
    condition     = contains(["external", "vm-series", "panorama-managed"], coalesce(try(var.palo_alto.deployment_model, null), "external"))
    error_message = "palo_alto.deployment_model must be one of external, vm-series, or panorama-managed."
  }

  validation {
    condition     = contains(["active-passive", "active-active", "external"], coalesce(try(var.palo_alto.ha_mode, null), "external"))
    error_message = "palo_alto.ha_mode must be active-passive, active-active, or external."
  }
}

variable "dns_resolution" {
  type = object({
    enabled                  = optional(bool, false)
    mode                     = optional(string, "dc-forwarders")
    private_resolver_enabled = optional(bool, false)
    dns_server_ips           = optional(list(string), [])
    notes                    = optional(string)
  })
  description = "DNS resolution posture contract for NET-27. This root records the approved mode without deploying Azure DNS Private Resolver unless a future module integration enables it."
  default     = {}

  validation {
    condition     = contains(["dc-forwarders", "private-resolver", "hybrid"], coalesce(try(var.dns_resolution.mode, null), "dc-forwarders"))
    error_message = "dns_resolution.mode must be dc-forwarders, private-resolver, or hybrid."
  }
}

variable "private_dns_resolver" {
  type = object({
    enabled             = optional(bool, false)
    name                = optional(string)
    resource_group_name = optional(string)
    location            = optional(string)
    virtual_network_id  = optional(string)
    inbound_endpoints = optional(map(object({
      subnet_key                   = optional(string)
      subnet_id                    = optional(string)
      private_ip_allocation_method = optional(string, "Dynamic")
      private_ip_address           = optional(string)
      tags                         = optional(map(string), {})
    })), {})
    outbound_endpoints = optional(map(object({
      subnet_key = optional(string)
      subnet_id  = optional(string)
      tags       = optional(map(string), {})
    })), {})
    forwarding_rulesets = optional(map(object({
      outbound_endpoint_keys = list(string)
      tags                   = optional(map(string), {})
    })), {})
    forwarding_rules = optional(map(object({
      ruleset_key = string
      domain_name = string
      enabled     = optional(bool, true)
      metadata    = optional(map(string))
      target_dns_servers = list(object({
        ip_address = string
        port       = optional(number, 53)
      }))
    })), {})
    forwarding_ruleset_vnet_links = optional(map(object({
      ruleset_key        = string
      virtual_network_id = optional(string)
      metadata           = optional(map(string))
    })), {})
  })
  description = "Optional Azure Private DNS Resolver deployment for NET-27 when the architecture chooses resolver-based forwarding."
  default     = {}

  validation {
    condition = alltrue(concat(
      [
        for endpoint in values(try(var.private_dns_resolver.inbound_endpoints, {})) :
        (try(endpoint.subnet_key, null) != null) != (try(endpoint.subnet_id, null) != null)
      ],
      [
        for endpoint in values(try(var.private_dns_resolver.outbound_endpoints, {})) :
        (try(endpoint.subnet_key, null) != null) != (try(endpoint.subnet_id, null) != null)
      ]
    ))
    error_message = "Each private DNS resolver endpoint must set exactly one of subnet_key or subnet_id."
  }
}

variable "bastion" {
  type = object({
    enabled                   = optional(bool, false)
    name                      = optional(string)
    resource_group_name       = optional(string)
    location                  = optional(string)
    subnet_key                = optional(string)
    subnet_id                 = optional(string)
    sku                       = optional(string, "Standard")
    copy_paste_enabled        = optional(bool, true)
    file_copy_enabled         = optional(bool, false)
    ip_connect_enabled        = optional(bool, false)
    kerberos_enabled          = optional(bool, false)
    session_recording_enabled = optional(bool, false)
    shareable_link_enabled    = optional(bool, false)
    tunneling_enabled         = optional(bool, true)
    scale_units               = optional(number, 2)
    public_ip_zones           = optional(list(string), [])
    public_ip_id              = optional(string)
    public_ip = optional(object({
      name                    = optional(string)
      allocation_method       = optional(string, "Static")
      sku                     = optional(string, "Standard")
      sku_tier                = optional(string, "Regional")
      domain_name_label       = optional(string)
      ip_version              = optional(string, "IPv4")
      idle_timeout_in_minutes = optional(number, 4)
      public_ip_prefix_id     = optional(string)
      reverse_fqdn            = optional(string)
      zones                   = optional(list(string))
      tags                    = optional(map(string), {})
    }), {})
    zones = optional(list(string))
    diagnostic_settings = optional(map(object({
      log_analytics_workspace_id     = optional(string)
      log_analytics_destination_type = optional(string)
      storage_account_id             = optional(string)
      eventhub_authorization_rule_id = optional(string)
      eventhub_name                  = optional(string)
      logs                           = optional(list(string), ["BastionAuditLogs"])
      metrics                        = optional(list(string), ["AllMetrics"])
    })), {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  })
  description = "Optional central Azure Bastion deployment for privileged access."
  default     = {}
}

variable "network_security_groups" {
  type = map(object({
    name = string
    rules = optional(map(object({
      priority                                   = number
      direction                                  = string
      access                                     = string
      protocol                                   = string
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(list(string))
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(list(string))
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(list(string))
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(list(string))
      source_application_security_group_ids      = optional(list(string))
      destination_application_security_group_ids = optional(list(string))
      description                                = optional(string)
    })), {})
  }))
  default = {}
}

variable "subnet_nsg_associations" {
  type = map(object({
    subnet_key = string
    nsg_key    = string
  }))
  default = {}
}

variable "route_tables" {
  type = map(object({
    name                          = string
    bgp_route_propagation_enabled = optional(bool, true)
    routes = optional(map(object({
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
  }))
  default = {}
}

variable "public_ips" {
  type = map(object({
    name                    = string
    allocation_method       = optional(string, "Static")
    sku                     = optional(string, "Standard")
    sku_tier                = optional(string, "Regional")
    ip_version              = optional(string, "IPv4")
    edge_zone               = optional(string)
    domain_name_label       = optional(string)
    domain_name_label_scope = optional(string)
    idle_timeout_in_minutes = optional(number, 4)
    public_ip_prefix_id     = optional(string)
    reverse_fqdn            = optional(string)
    ddos_protection_mode    = optional(string)
    ddos_protection_plan_id = optional(string)
    ip_tags                 = optional(map(string), {})
    zones                   = optional(list(string), [])
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  description = "Optional public IPs for approved egress or ingress patterns such as firewall untrust interfaces. Defaults to no resources."
  default     = {}
}

variable "route_server_public_ips" {
  type = map(object({
    name                    = string
    resource_group_name     = optional(string)
    location                = optional(string)
    allocation_method       = optional(string, "Static")
    sku                     = optional(string, "Standard")
    sku_tier                = optional(string, "Regional")
    ip_version              = optional(string, "IPv4")
    edge_zone               = optional(string)
    domain_name_label       = optional(string)
    domain_name_label_scope = optional(string)
    idle_timeout_in_minutes = optional(number, 4)
    public_ip_prefix_id     = optional(string)
    reverse_fqdn            = optional(string)
    ddos_protection_mode    = optional(string)
    ddos_protection_plan_id = optional(string)
    ip_tags                 = optional(map(string), {})
    zones                   = optional(list(string), [])
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
    tags = optional(map(string), {})
  }))
  description = "Optional public IPs for Azure Route Server."
  default     = {}
}

variable "route_servers" {
  type = map(object({
    name                             = string
    resource_group_name              = optional(string)
    location                         = optional(string)
    sku                              = optional(string, "Standard")
    subnet_key                       = optional(string)
    subnet_id                        = optional(string)
    public_ip_key                    = optional(string)
    public_ip_address_id             = optional(string)
    branch_to_branch_traffic_enabled = optional(bool, true)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
    bgp_connections = optional(map(object({
      name                 = string
      peer_asn             = number
      peer_ip              = string
      ipv4_route_server_id = optional(string)
      timeouts = optional(object({
        create = optional(string)
        read   = optional(string)
        delete = optional(string)
      }), {})
    })), {})
    tags = optional(map(string), {})
  }))
  description = "Optional Azure Route Server instances and BGP peerings."
  default     = {}

  validation {
    condition = alltrue([
      for route_server in values(var.route_servers) :
      (try(route_server.subnet_key, null) != null) != (try(route_server.subnet_id, null) != null)
    ])
    error_message = "Each route_servers item must set exactly one of subnet_key or subnet_id."
  }

  validation {
    condition = alltrue([
      for route_server in values(var.route_servers) :
      (try(route_server.public_ip_key, null) != null) != (try(route_server.public_ip_address_id, null) != null)
    ])
    error_message = "Each route_servers item must set exactly one of public_ip_key or public_ip_address_id."
  }
}

variable "load_balancers" {
  type = map(object({
    name      = string
    sku       = optional(string, "Standard")
    sku_tier  = optional(string)
    edge_zone = optional(string)
    frontend_ip_configurations = map(object({
      subnet_key                                         = optional(string)
      subnet_id                                          = optional(string)
      private_ip_address                                 = optional(string)
      private_ip_address_allocation                      = optional(string)
      private_ip_address_version                         = optional(string)
      public_ip_key                                      = optional(string)
      public_ip_address_id                               = optional(string)
      public_ip_prefix_id                                = optional(string)
      gateway_load_balancer_frontend_ip_configuration_id = optional(string)
      zones                                              = optional(list(string))
    }))
    backend_address_pools = optional(map(object({
      virtual_network_id = optional(string)
      synchronous_mode   = optional(string)
      tunnel_interfaces = optional(map(object({
        identifier = number
        type       = string
        protocol   = string
        port       = number
      })), {})
      timeouts = optional(object({
        create = optional(string)
        update = optional(string)
        read   = optional(string)
        delete = optional(string)
      }), {})
    })), {})
    backend_addresses = optional(map(object({
      backend_address_pool_name           = optional(string)
      backend_address_pool_id             = optional(string)
      virtual_network_id                  = optional(string)
      ip_address                          = optional(string)
      backend_address_ip_configuration_id = optional(string)
      timeouts = optional(object({
        create = optional(string)
        update = optional(string)
        read   = optional(string)
        delete = optional(string)
      }), {})
    })), {})
    probes = optional(map(object({
      protocol            = string
      port                = number
      request_path        = optional(string)
      interval_in_seconds = optional(number, 5)
      number_of_probes    = optional(number, 2)
      probe_threshold     = optional(number)
      timeouts = optional(object({
        create = optional(string)
        update = optional(string)
        read   = optional(string)
        delete = optional(string)
      }), {})
    })), {})
    rules = optional(map(object({
      protocol                       = string
      frontend_port                  = number
      backend_port                   = number
      frontend_ip_configuration_name = string
      backend_address_pool_names     = optional(list(string), [])
      backend_address_pool_ids       = optional(list(string), [])
      probe_name                     = optional(string)
      probe_id                       = optional(string)
      load_distribution              = optional(string, "Default")
      disable_outbound_snat          = optional(bool, false)
      idle_timeout_in_minutes        = optional(number, 4)
      enable_floating_ip             = optional(bool)
      floating_ip_enabled            = optional(bool)
      tcp_reset_enabled              = optional(bool)
      timeouts = optional(object({
        create = optional(string)
        update = optional(string)
        read   = optional(string)
        delete = optional(string)
      }), {})
    })), {})
    nat_rules = optional(map(object({
      protocol                       = string
      frontend_ip_configuration_name = string
      backend_port                   = number
      backend_address_pool_name      = optional(string)
      backend_address_pool_id        = optional(string)
      frontend_port                  = optional(number)
      frontend_port_start            = optional(number)
      frontend_port_end              = optional(number)
      idle_timeout_in_minutes        = optional(number)
      enable_floating_ip             = optional(bool)
      floating_ip_enabled            = optional(bool)
      tcp_reset_enabled              = optional(bool)
      timeouts = optional(object({
        create = optional(string)
        update = optional(string)
        read   = optional(string)
        delete = optional(string)
      }), {})
    })), {})
    outbound_rules = optional(map(object({
      protocol                        = string
      backend_address_pool_name       = optional(string)
      backend_address_pool_id         = optional(string)
      frontend_ip_configuration_names = list(string)
      allocated_outbound_ports        = optional(number)
      idle_timeout_in_minutes         = optional(number)
      tcp_reset_enabled               = optional(bool)
      timeouts = optional(object({
        create = optional(string)
        update = optional(string)
        read   = optional(string)
        delete = optional(string)
      }), {})
    })), {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  description = "Optional internal or external load balancers for approved network appliance patterns. Defaults to no resources."
  default     = {}

  validation {
    condition = alltrue(flatten([
      for lb in values(var.load_balancers) : [
        for frontend in values(lb.frontend_ip_configurations) :
        length(compact([
          try(frontend.subnet_key, null),
          try(frontend.subnet_id, null),
          try(frontend.public_ip_key, null),
          try(frontend.public_ip_address_id, null),
          try(frontend.public_ip_prefix_id, null)
        ])) > 0
      ]
    ]))
    error_message = "Each load balancer frontend must set at least one of subnet_key, subnet_id, public_ip_key, or public_ip_address_id."
  }
}

variable "subnet_route_table_associations" {
  type = map(object({
    subnet_key      = string
    route_table_key = string
  }))
  default = {}
}

variable "network_watchers" {
  type = map(object({
    name                = string
    resource_group_name = optional(string)
    location            = optional(string)
    tags                = optional(map(string), {})
  }))
  description = "Optional Network Watchers to create when the regional watcher is not managed elsewhere."
  default     = {}
}

variable "local_network_gateways" {
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
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  description = "Optional on-premises local network gateways for future S2S VPN or route validation."
  default     = {}
}

variable "network_watcher_flow_logs" {
  type = map(object({
    name                       = string
    network_watcher_key        = optional(string)
    network_watcher_name       = optional(string)
    resource_group_name        = optional(string)
    network_security_group_key = optional(string)
    network_security_group_id  = optional(string)
    storage_account_id         = string
    enabled                    = optional(bool, true)
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
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  description = "NSG flow logs and traffic analytics for connectivity subnets."
  default     = {}

  validation {
    condition = alltrue([
      for flow_log in values(var.network_watcher_flow_logs) :
      (try(flow_log.network_watcher_key, null) != null) != (try(flow_log.network_watcher_name, null) != null)
    ])
    error_message = "Each network_watcher_flow_logs item must set exactly one of network_watcher_key or network_watcher_name."
  }

  validation {
    condition = alltrue([
      for flow_log in values(var.network_watcher_flow_logs) :
      (try(flow_log.network_security_group_key, null) != null) != (try(flow_log.network_security_group_id, null) != null)
    ])
    error_message = "Each network_watcher_flow_logs item must set exactly one of network_security_group_key or network_security_group_id."
  }
}

variable "private_dns_zones" {
  type = map(object({
    name                 = string
    resource_group_name  = optional(string)
    link_to_hub          = optional(bool, true)
    registration_enabled = optional(bool, false)
  }))
  default = {}
}

variable "additional_scopes" {
  type        = map(string)
  description = "Additional named scopes that can be referenced by locks, diagnostics, or role assignments."
  default     = {}
}

variable "role_assignments" {
  type = map(object({
    name                                   = optional(string)
    scope_key                              = optional(string)
    scope                                  = optional(string)
    principal_id                           = string
    role_definition_name                   = optional(string)
    role_definition_id                     = optional(string)
    principal_type                         = optional(string)
    description                            = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    skip_service_principal_aad_check       = optional(bool)
    delegated_managed_identity_resource_id = optional(string)
  }))
  description = "RBAC assignments for platform connectivity resources."
  default     = {}

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) :
      (
        (try(assignment.scope, null) != null || try(assignment.scope_key, null) != null) &&
        !(try(assignment.scope, null) != null && try(assignment.scope_key, null) != null)
      )
    ])
    error_message = "Each role assignment must set exactly one of scope or scope_key."
  }
}

variable "management_locks" {
  type = map(object({
    name       = string
    scope_key  = optional(string)
    scope      = optional(string)
    lock_level = string
    notes      = optional(string)
  }))
  description = "Locks for critical platform connectivity resources."
  default     = {}

  validation {
    condition = alltrue([
      for item in values(var.management_locks) :
      (
        (try(item.scope, null) != null || try(item.scope_key, null) != null) &&
        !(try(item.scope, null) != null && try(item.scope_key, null) != null)
      )
    ])
    error_message = "Each management lock must set exactly one of scope or scope_key."
  }
}

variable "diagnostic_settings" {
  type = map(object({
    name                           = string
    target_key                     = optional(string)
    target_resource_id             = optional(string)
    log_analytics_workspace_id     = optional(string)
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    partner_solution_id            = optional(string)
    logs = optional(map(object({
      category       = optional(string)
      category_group = optional(string)
    })), {})
    metrics = optional(map(object({
      category = string
      enabled  = optional(bool, true)
    })), {})
  }))
  description = "Diagnostics for connectivity resources that support Azure Monitor diagnostic settings."
  default     = {}

  validation {
    condition = alltrue([
      for item in values(var.diagnostic_settings) :
      (
        (try(item.target_resource_id, null) != null || try(item.target_key, null) != null) &&
        !(try(item.target_resource_id, null) != null && try(item.target_key, null) != null)
      )
    ])
    error_message = "Each diagnostic setting must set exactly one of target_resource_id or target_key."
  }
}
