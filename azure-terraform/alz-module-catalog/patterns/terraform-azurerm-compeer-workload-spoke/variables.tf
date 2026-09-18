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
    application           = optional(string)
    appcode               = optional(string)
    owner                 = optional(string)
    source_repo           = optional(string)
    created_on            = optional(string)
    criticality_tier      = optional(string)
    data_classification   = optional(string)
    lifecycle_state       = optional(string)
    cost_center           = optional(string)
    gl_category           = optional(string)
    application_component = optional(string)
    modified_on           = optional(string)
    created_by            = optional(string)
    dr_tier               = optional(string)
    expiration_date       = optional(string)
    additional_tags       = optional(map(string), {})
  })
  default = {}
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
      route_table_key                               = optional(string)
      nsg_key                                       = optional(string)
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

variable "workload_storage_accounts" {
  description = <<-EOT
    Optional workload storage accounts, keyed by logical name (an app can
    deploy more than one - e.g. "data" and "logs"). Every DR/resiliency knob
    the underlying module exposes is a caller-overridable default here, not a
    fixed choice - account_replication_type defaults to ZRS (zone-redundant)
    but a caller can set GRS/GZRS for cross-region resilience, or LRS for a
    genuinely disposable/dev workload; blob versioning + soft-delete +
    restore_policy are on by default for the same reason RSV backups exist -
    protecting against accidental deletion/corruption, not just outages.
    Defaults to no resources.
  EOT
  type = map(object({
    name                              = string
    account_tier                      = optional(string, "Standard")
    account_replication_type          = optional(string, "ZRS")
    account_kind                      = optional(string, "StorageV2")
    access_tier                       = optional(string, "Hot")
    edge_zone                         = optional(string)
    min_tls_version                   = optional(string, "TLS1_2")
    https_traffic_only_enabled        = optional(bool, true)
    public_network_access_enabled     = optional(bool, false)
    allow_nested_items_to_be_public   = optional(bool, false)
    shared_access_key_enabled         = optional(bool, false)
    infrastructure_encryption_enabled = optional(bool, true)
    is_hns_enabled                    = optional(bool, false)
    sftp_enabled                      = optional(bool, false)
    local_user_enabled                = optional(bool, false)
    nfsv3_enabled                     = optional(bool, false)
    large_file_share_enabled          = optional(bool, false)
    cross_tenant_replication_enabled  = optional(bool, false)
    default_to_oauth_authentication   = optional(bool, true)
    allowed_copy_scope                = optional(string)
    dns_endpoint_type                 = optional(string)
    queue_encryption_key_type         = optional(string)
    table_encryption_key_type         = optional(string)
    provisioned_billing_model_version = optional(string)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    customer_managed_key = optional(object({
      key_vault_key_id          = optional(string)
      managed_hsm_key_id        = optional(string)
      user_assigned_identity_id = optional(string)
    }))
    network_rules = optional(object({
      default_action             = string
      bypass                     = optional(list(string), ["AzureServices"])
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
      private_link_access = optional(map(object({
        endpoint_resource_id = string
        endpoint_tenant_id   = optional(string)
      })), {})
    }))
    # versioning + soft delete + restore_policy default ON: this is the data-
    # protection equivalent of RSV backups for blob data (recover from
    # accidental delete/overwrite, not just an outage).
    blob_properties = optional(object({
      versioning_enabled                = optional(bool, true)
      change_feed_enabled               = optional(bool, true)
      change_feed_retention_in_days     = optional(number)
      default_service_version           = optional(string)
      last_access_time_enabled          = optional(bool, false)
      delete_retention_days             = optional(number, 30)
      container_delete_retention_days   = optional(number, 30)
      restore_policy                    = optional(object({ days = number }), { days = 29 })
      delete_retention_policy           = optional(object({ days = optional(number), permanent_delete_enabled = optional(bool) }))
      container_delete_retention_policy = optional(object({ days = optional(number) }))
      cors_rules = optional(map(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })), {})
    }), {})
    queue_properties = optional(object({
      logging = optional(object({
        delete                = optional(bool, true)
        read                  = optional(bool, true)
        write                 = optional(bool, true)
        version               = optional(string, "1.0")
        retention_policy_days = optional(number)
      }))
      hour_metrics = optional(object({
        enabled               = bool
        version               = string
        include_apis          = optional(bool)
        retention_policy_days = optional(number)
      }))
      minute_metrics = optional(object({
        enabled               = bool
        version               = string
        include_apis          = optional(bool)
        retention_policy_days = optional(number)
      }))
      cors_rules = optional(map(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })), {})
    }))
    share_properties = optional(object({
      retention_policy = optional(object({
        days = optional(number)
      }))
      smb = optional(object({
        versions                        = optional(set(string))
        authentication_types            = optional(set(string))
        kerberos_ticket_encryption_type = optional(set(string))
        channel_encryption_type         = optional(set(string))
        multichannel_enabled            = optional(bool)
      }))
      cors_rules = optional(map(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })), {})
    }))
    azure_files_authentication = optional(object({
      directory_type                 = string
      default_share_level_permission = optional(string)
      active_directory = optional(object({
        domain_name         = string
        domain_guid         = string
        domain_sid          = optional(string)
        storage_sid         = optional(string)
        forest_name         = optional(string)
        netbios_domain_name = optional(string)
      }))
    }))
    custom_domain = optional(object({
      name          = string
      use_subdomain = optional(bool)
    }))
    immutability_policy = optional(object({
      allow_protected_append_writes = optional(bool)
      period_since_creation_in_days = number
      state                         = string
    }))
    routing = optional(object({
      choice                      = optional(string)
      publish_internet_endpoints  = optional(bool)
      publish_microsoft_endpoints = optional(bool)
    }))
    sas_policy = optional(object({
      expiration_period = string
      expiration_action = optional(string)
    }))
    static_website = optional(object({
      index_document     = string
      error_404_document = optional(string)
    }))
    # No dedicated role_assignments field here: register this entry into
    # workload_scope_ids ("storage:<key>") and use the pattern's existing
    # generic var.role_assignments / var.management_locks with
    # scope_key = "storage:<key>" - the same mechanism NSGs and route tables
    # already use, instead of a third, redundant per-resource-type RBAC path.
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
      })), { allLogs = { category_group = "allLogs" } })
      metrics = optional(map(object({
        category = string
        enabled  = optional(bool, true)
      })), { AllMetrics = { category = "AllMetrics" } })
    }), {})
    private_endpoint = optional(object({
      name                            = string
      subnet_key                      = optional(string)
      subnet_id                       = optional(string)
      subresource_name                = optional(string, "blob")
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
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.workload_storage_accounts :
      v.private_endpoint == null || (
        try(v.private_endpoint.subnet_key, null) == null || try(v.private_endpoint.subnet_id, null) == null
      )
    ])
    error_message = "workload_storage_accounts[*].private_endpoint must not set both subnet_key and subnet_id."
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
    lock_level = optional(string, "CanNotDelete")
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
    # Platform_Output_Contracts_IAC-10 management_diagnostic_profile - keep
    # in sync with modules/terraform-azurerm-compeer-diagnostic-profile's
    # defaults (allLogs / AllMetrics). Only applies to an entry that leaves
    # logs/metrics unset - an explicit value here always wins.
    logs = optional(map(object({
      category       = optional(string)
      category_group = optional(string)
    })), { allLogs = { category_group = "allLogs" } })
    metrics = optional(map(object({
      category = string
      enabled  = optional(bool, true)
    })), { AllMetrics = { category = "AllMetrics" } })
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

variable "private_endpoints" {
  description = <<-EOT
    Workload private endpoints keyed by a caller-stable name. Each targets a
    resource by `private_connection_resource_id` with `subresource_names`
    (e.g. ["blob"], ["vault"], ["sqlServer"]), lands on a spoke subnet
    (`subnet_key`, default "private_endpoints"), and links `private_dns_zone_ids`.
  EOT
  type = map(object({
    name                            = string
    private_connection_resource_id  = string
    subresource_names               = list(string)
    subnet_key                      = optional(string)
    subnet_id                       = optional(string)
    private_dns_zone_ids            = optional(list(string), [])
    private_dns_zone_group_name     = optional(string)
    private_service_connection_name = optional(string)
    custom_network_interface_name   = optional(string)
    is_manual_connection            = optional(bool, false)
    request_message                 = optional(string)
    edge_zone                       = optional(string)
    ip_configurations = optional(list(object({
      name               = string
      private_ip_address = string
      subresource_name   = optional(string)
      member_name        = optional(string)
    })), [])
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default = {}
}
