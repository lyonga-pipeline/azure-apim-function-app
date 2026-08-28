variable "subscription_id" {
  type        = string
  description = "Workload subscription id."
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant id. Leave null to use the tenant from the active Azure credentials."
  default     = null
}

variable "location" {
  type        = string
  description = "Azure region for workload spoke resources."
}

variable "environment" {
  type        = string
  description = "Environment key, such as np1, np2, np3, or prod."
}

variable "workload_tags" {
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

variable "spoke_vnet" {
  type = object({
    name                           = string
    address_space                  = list(string)
    dns_servers                    = optional(list(string))
    bgp_community                  = optional(string)
    edge_zone                      = optional(string)
    flow_timeout_in_minutes        = optional(number)
    private_endpoint_vnet_policies = optional(string)
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

variable "subnet_route_table_associations" {
  type = map(object({
    subnet_key      = string
    route_table_key = string
  }))
  default = {}
}

variable "hub_connection" {
  type = object({
    hub_virtual_network_id  = string
    allow_forwarded_traffic = optional(bool, true)
    allow_gateway_transit   = optional(bool, false)
    use_remote_gateways     = optional(bool, false)
  })
  default = null
}

variable "private_dns_zone_links" {
  type = map(object({
    private_dns_zone_name = string
    resource_group_name   = string
    registration_enabled  = optional(bool, false)
  }))
  default = {}
}

variable "workload_identity" {
  type = object({
    enabled = optional(bool, false)
    name    = optional(string)
  })
  description = "Optional workload user-assigned managed identity."
  default     = {}
}

variable "workload_key_vault" {
  type = object({
    enabled                    = optional(bool, false)
    name                       = optional(string)
    sku_name                   = optional(string, "premium")
    soft_delete_retention_days = optional(number, 90)
    purge_protection_enabled   = optional(bool, true)
    rbac_authorization_enabled = optional(bool, true)
    access_policies = optional(list(object({
      tenant_id               = string
      object_id               = string
      application_id          = optional(string)
      key_permissions         = optional(list(string), [])
      secret_permissions      = optional(list(string), [])
      certificate_permissions = optional(list(string))
      storage_permissions     = optional(list(string))
    })), [])
    access_policies_by_key = optional(map(object({
      tenant_id               = string
      object_id               = string
      application_id          = optional(string)
      key_permissions         = optional(list(string), [])
      secret_permissions      = optional(list(string), [])
      certificate_permissions = optional(list(string), [])
      storage_permissions     = optional(list(string), [])
    })), {})
    enabled_for_deployment          = optional(bool, false)
    enabled_for_disk_encryption     = optional(bool, true)
    enabled_for_template_deployment = optional(bool, false)
    public_network_access_enabled   = optional(bool, false)
    network_acls = optional(object({
      default_action             = string
      bypass                     = optional(string, "AzureServices")
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
    }))
    contacts = optional(map(object({
      email = string
      name  = optional(string)
      phone = optional(string)
    })), {})
    role_assignments = optional(map(object({
      name                                   = optional(string)
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
    })), {})
    diagnostics = optional(object({
      enabled                        = optional(bool, true)
      name                           = optional(string)
      log_analytics_workspace_id     = optional(string)
      storage_account_id             = optional(string)
      eventhub_authorization_rule_id = optional(string)
      eventhub_name                  = optional(string)
      partner_solution_id            = optional(string)
      log_analytics_destination_type = optional(string)
      logs = optional(map(object({
        category       = optional(string)
        category_group = optional(string)
      })), {})
      metrics = optional(map(object({
        category = string
        enabled  = optional(bool, true)
      })), {})
    }), {})
    private_endpoint = optional(object({
      name                            = string
      subnet_key                      = optional(string)
      subnet_id                       = optional(string)
      custom_network_interface_name   = optional(string)
      private_service_connection_name = optional(string)
      private_dns_zone_group_name     = optional(string, "default")
      private_dns_zone_ids            = optional(list(string), [])
      edge_zone                       = optional(string)
      ip_configurations = optional(list(object({
        name               = string
        private_ip_address = string
        subresource_name   = string
        member_name        = string
      })), [])
      timeouts = optional(object({
        create = optional(string)
        update = optional(string)
        read   = optional(string)
        delete = optional(string)
      }), {})
    }))
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  })
  description = "Optional workload Key Vault pattern using Compeer Key Vault, RBAC, diagnostics, and private endpoint modules."
  default     = {}

  validation {
    condition = (
      !coalesce(try(var.workload_key_vault.enabled, null), false) ||
      try(var.workload_key_vault.name, null) != null
    )
    error_message = "workload_key_vault.name is required when workload_key_vault.enabled is true."
  }

  validation {
    condition = (
      try(var.workload_key_vault.private_endpoint, null) == null ||
      try(var.workload_key_vault.private_endpoint.subnet_key, null) == null ||
      try(var.workload_key_vault.private_endpoint.subnet_id, null) == null
    )
    error_message = "workload_key_vault.private_endpoint must not set both subnet_key and subnet_id."
  }
}

variable "additional_scopes" {
  type        = map(string)
  description = "Any Additional named scopes that can be referenced by locks, diagnostics, or role assignments."
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
  description = "RBAC assignments for workload spoke resources."
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
  description = "Locks for critical workload landing-zone resources."
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
  description = "Diagnostics for workload spoke resources that support Azure Monitor diagnostic settings."
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
