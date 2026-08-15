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
    name          = string
    address_space = list(string)
    dns_servers   = optional(list(string))
    subnets = map(object({
      address_prefixes                              = list(string)
      service_endpoints                             = optional(list(string), [])
      private_endpoint_network_policies             = optional(string, "Enabled")
      private_link_service_network_policies_enabled = optional(bool, true)
      delegations = optional(map(object({
        name    = string
        actions = optional(list(string), [])
      })), {})
    }))
  })
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

variable "network_security_groups" {
  type = map(object({
    name       = string
    subnet_key = optional(string)
    subnet_id  = optional(string)
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
    domain_name_label       = optional(string)
    idle_timeout_in_minutes = optional(number, 4)
    public_ip_prefix_id     = optional(string)
    reverse_fqdn            = optional(string)
    zones                   = optional(list(string), [])
  }))
  description = "Optional public IPs for approved egress or ingress patterns such as firewall untrust interfaces. Defaults to no resources."
  default     = {}
}

variable "load_balancers" {
  type = map(object({
    name      = string
    sku       = optional(string, "Standard")
    edge_zone = optional(string)
    frontend_ip_configurations = map(object({
      subnet_key                    = optional(string)
      subnet_id                     = optional(string)
      private_ip_address            = optional(string)
      private_ip_address_allocation = optional(string)
      public_ip_key                 = optional(string)
      public_ip_address_id          = optional(string)
      zones                         = optional(list(string))
    }))
    backend_address_pools = optional(map(object({})), {})
    probes = optional(map(object({
      protocol            = string
      port                = number
      request_path        = optional(string)
      interval_in_seconds = optional(number, 5)
      number_of_probes    = optional(number, 2)
    })), {})
    rules = optional(map(object({
      protocol                       = string
      frontend_port                  = number
      backend_port                   = number
      frontend_ip_configuration_name = string
      backend_address_pool_names     = list(string)
      probe_name                     = optional(string)
      load_distribution              = optional(string, "Default")
      disable_outbound_snat          = optional(bool, false)
      idle_timeout_in_minutes        = optional(number, 4)
      enable_floating_ip             = optional(bool, false)
    })), {})
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
          try(frontend.public_ip_address_id, null)
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
