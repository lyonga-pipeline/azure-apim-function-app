variable "subscription_id" {
  type        = string
  description = "Platform management subscription id."
}

variable "location" {
  type        = string
  description = "Azure region for management resources."
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

variable "log_analytics" {
  type = object({
    name                             = string
    sku                              = optional(string, "PerGB2018")
    retention_in_days                = optional(number, 90)
    daily_quota_gb                   = optional(number)
    security_center_subscriptions    = optional(list(string), [])
    contributors                     = optional(list(string), [])
    contributor_role_definition_name = optional(string)
    contributors_by_key = optional(map(object({
      principal_id         = string
      role_definition_name = optional(string)
      role_definition_id   = optional(string)
      principal_type       = optional(string)
      description          = optional(string)
    })), {})
    allow_resource_only_permissions         = optional(bool)
    cmk_for_query_forced                    = optional(bool)
    data_collection_rule_id                 = optional(string)
    immediate_data_purge_on_30_days_enabled = optional(bool)
    internet_ingestion_enabled              = optional(bool)
    internet_query_enabled                  = optional(bool)
    local_authentication_disabled           = optional(bool)
    reservation_capacity_in_gb_per_day      = optional(number)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  })
}

variable "action_group" {
  type = object({
    name       = string
    short_name = string
    enabled    = optional(bool, true)
    receivers = optional(object({
      email = optional(map(object({
        email_address           = string
        use_common_alert_schema = optional(bool, true)
      })), {})
      webhook = optional(map(object({
        service_uri             = string
        use_common_alert_schema = optional(bool, true)
      })), {})
      sms = optional(map(object({
        country_code = string
        phone_number = string
      })), {})
      voice = optional(map(object({
        country_code = string
        phone_number = string
      })), {})
      arm_role = optional(map(object({
        role_id                 = string
        use_common_alert_schema = optional(bool, true)
      })), {})
      automation_runbook = optional(map(object({
        automation_account_id   = string
        runbook_name            = string
        webhook_resource_id     = string
        is_global_runbook       = bool
        service_uri             = string
        use_common_alert_schema = optional(bool, true)
      })), {})
      azure_app_push = optional(map(object({
        email_address = string
      })), {})
      azure_function = optional(map(object({
        function_app_resource_id = string
        function_name            = string
        http_trigger_url         = string
        use_common_alert_schema  = optional(bool, true)
      })), {})
      event_hub = optional(map(object({
        event_hub_name          = string
        event_hub_namespace     = string
        subscription_id         = string
        tenant_id               = optional(string)
        use_common_alert_schema = optional(bool, true)
      })), {})
      itsm = optional(map(object({
        workspace_id         = string
        connection_id        = string
        ticket_configuration = string
        region               = string
      })), {})
      logic_app = optional(map(object({
        resource_id             = string
        callback_url            = string
        use_common_alert_schema = optional(bool, true)
      })), {})
    }), {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  })
}

variable "platform_storage_accounts" {
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
    blob_properties = optional(object({
      versioning_enabled                = optional(bool, true)
      change_feed_enabled               = optional(bool, true)
      change_feed_retention_in_days     = optional(number)
      default_service_version           = optional(string)
      last_access_time_enabled          = optional(bool, false)
      delete_retention_days             = optional(number)
      container_delete_retention_days   = optional(number)
      restore_policy                    = optional(object({ days = number }))
      delete_retention_policy           = optional(object({ days = optional(number), permanent_delete_enabled = optional(bool) }))
      container_delete_retention_policy = optional(object({ days = optional(number) }))
      cors_rules = optional(map(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })), {})
    }))
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
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  description = "Optional platform storage accounts for diagnostics archive, bootstrap, or platform artifacts. Defaults to no resources."
  default     = {}
}

variable "platform_key_vaults" {
  type = map(object({
    name      = string
    sku_name  = optional(string, "standard")
    tenant_id = optional(string)
    access_policies = optional(list(object({
      tenant_id               = string
      object_id               = string
      application_id          = optional(string)
      key_permissions         = optional(list(string), [])
      secret_permissions      = optional(list(string), [])
      certificate_permissions = optional(list(string), [])
      storage_permissions     = optional(list(string), [])
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
    rbac_authorization_enabled      = optional(bool, true)
    enable_rbac_authorization       = optional(bool)
    enabled_for_deployment          = optional(bool, false)
    enabled_for_disk_encryption     = optional(bool, false)
    enabled_for_template_deployment = optional(bool, false)
    purge_protection_enabled        = optional(bool, true)
    public_network_access_enabled   = optional(bool, false)
    soft_delete_retention_days      = optional(number, 90)
    network_acls = optional(object({
      default_action             = string
      bypass                     = string
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
      }), {
      bypass         = "AzureServices"
      default_action = "Deny"
    })
    contacts = optional(list(object({
      email = string
      name  = optional(string)
      phone = optional(string)
    })), [])
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  description = "Optional platform Key Vaults for platform secrets, certificates, and controlled bootstrap material. Secret/key/certificate assets remain outside this resource module."
  default     = {}
}

variable "recovery_services_vaults" {
  type = map(object({
    name                               = string
    sku                                = optional(string, "Standard")
    soft_delete_enabled                = optional(bool, true)
    storage_mode_type                  = optional(string, "GeoRedundant")
    public_network_access_enabled      = optional(bool)
    immutability                       = optional(string)
    cross_region_restore_enabled       = optional(bool)
    classic_vmware_replication_enabled = optional(bool)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    encryption = optional(object({
      key_id                            = string
      infrastructure_encryption_enabled = optional(bool)
      use_system_assigned_identity      = optional(bool)
      user_assigned_identity_id         = optional(string)
    }))
    monitoring = optional(object({
      alerts_for_all_job_failures_enabled            = optional(bool)
      alerts_for_all_failover_issues_enabled         = optional(bool)
      alerts_for_all_replication_issues_enabled      = optional(bool)
      alerts_for_critical_operation_failures_enabled = optional(bool)
      email_notifications_for_site_recovery_enabled  = optional(bool)
    }))
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  description = "Optional Recovery Services Vaults for platform backup posture. Defaults to no resources."
  default     = {}
}

variable "platform_storage_diagnostics" {
  type = map(object({
    name                           = string
    storage_account_key            = optional(string)
    target_resource_id             = optional(string)
    log_analytics_workspace_id     = optional(string)
    log_analytics_destination_type = optional(string)
    archive_storage_account_id     = optional(string)
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
  description = "Diagnostic settings for platform storage accounts."
  default     = {}

  validation {
    condition = alltrue([
      for item in values(var.platform_storage_diagnostics) :
      (
        (try(item.storage_account_key, null) != null || try(item.target_resource_id, null) != null) &&
        !(try(item.storage_account_key, null) != null && try(item.target_resource_id, null) != null)
      )
    ])
    error_message = "Each platform storage diagnostic setting must set exactly one of storage_account_key or target_resource_id."
  }
}

variable "platform_key_vault_diagnostics" {
  type = map(object({
    name                           = string
    key_vault_key                  = optional(string)
    target_resource_id             = optional(string)
    log_analytics_workspace_id     = optional(string)
    log_analytics_destination_type = optional(string)
    archive_storage_account_id     = optional(string)
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
  description = "Diagnostic settings for platform Key Vaults."
  default     = {}

  validation {
    condition = alltrue([
      for item in values(var.platform_key_vault_diagnostics) :
      (
        (try(item.key_vault_key, null) != null || try(item.target_resource_id, null) != null) &&
        !(try(item.key_vault_key, null) != null && try(item.target_resource_id, null) != null)
      )
    ])
    error_message = "Each platform Key Vault diagnostic setting must set exactly one of key_vault_key or target_resource_id."
  }
}

variable "platform_storage_private_endpoints" {
  type = map(object({
    name                            = string
    storage_account_key             = optional(string)
    private_connection_resource_id  = optional(string)
    subresource_name                = string
    subnet_id                       = string
    resource_group_name             = optional(string)
    location                        = optional(string)
    edge_zone                       = optional(string)
    custom_network_interface_name   = optional(string)
    private_service_connection_name = optional(string)
    is_manual_connection            = optional(bool, false)
    request_message                 = optional(string)
    private_dns_zone_group_name     = optional(string, "default")
    private_dns_zone_ids            = optional(list(string), [])
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
  description = "Private endpoints for Compeer platform storage accounts, usually blob/file/queue endpoints."
  default     = {}

  validation {
    condition = alltrue([
      for item in values(var.platform_storage_private_endpoints) :
      (
        (try(item.storage_account_key, null) != null || try(item.private_connection_resource_id, null) != null) &&
        !(try(item.storage_account_key, null) != null && try(item.private_connection_resource_id, null) != null)
      )
    ])
    error_message = "Each platform storage private endpoint must set exactly one of storage_account_key or private_connection_resource_id."
  }
}

variable "platform_key_vault_private_endpoints" {
  type = map(object({
    name                            = string
    key_vault_key                   = optional(string)
    private_connection_resource_id  = optional(string)
    subresource_name                = optional(string, "vault")
    subnet_id                       = string
    resource_group_name             = optional(string)
    location                        = optional(string)
    edge_zone                       = optional(string)
    custom_network_interface_name   = optional(string)
    private_service_connection_name = optional(string)
    is_manual_connection            = optional(bool, false)
    request_message                 = optional(string)
    private_dns_zone_group_name     = optional(string, "default")
    private_dns_zone_ids            = optional(list(string), [])
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
  description = "Private endpoints for platform Key Vaults."
  default     = {}

  validation {
    condition = alltrue([
      for item in values(var.platform_key_vault_private_endpoints) :
      (
        (try(item.key_vault_key, null) != null || try(item.private_connection_resource_id, null) != null) &&
        !(try(item.key_vault_key, null) != null && try(item.private_connection_resource_id, null) != null)
      )
    ])
    error_message = "Each platform Key Vault private endpoint must set exactly one of key_vault_key or private_connection_resource_id."
  }
}

variable "recovery_services_vault_diagnostics" {
  type = map(object({
    name                           = string
    recovery_services_vault_key    = optional(string)
    target_resource_id             = optional(string)
    log_analytics_workspace_id     = optional(string)
    log_analytics_destination_type = optional(string)
    archive_storage_account_id     = optional(string)
    eventhub_authorization_rule_id = optional(
      string
    )
    eventhub_name       = optional(string)
    partner_solution_id = optional(string)
    logs = optional(map(object({
      category       = optional(string)
      category_group = optional(string)
    })), {})
    metrics = optional(map(object({
      category = string
      enabled  = optional(bool, true)
    })), {})
  }))
  description = "Diagnostic settings for Recovery Services Vaults."
  default     = {}

  validation {
    condition = alltrue([
      for item in values(var.recovery_services_vault_diagnostics) :
      (
        (try(item.recovery_services_vault_key, null) != null || try(item.target_resource_id, null) != null) &&
        !(try(item.recovery_services_vault_key, null) != null && try(item.target_resource_id, null) != null)
      )
    ])
    error_message = "Each Recovery Services Vault diagnostic setting must set exactly one of recovery_services_vault_key or target_resource_id."
  }
}

variable "data_collection_endpoints" {
  type = map(object({
    name                          = string
    kind                          = optional(string)
    description                   = optional(string)
    public_network_access_enabled = optional(bool)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  description = "Azure Monitor Data Collection Endpoints for AMA/DCR-based telemetry."
  default     = {}
}

variable "data_collection_rules" {
  type        = any
  description = "Azure Monitor Data Collection Rules. DCR lifecycle remains separate from target resource associations."
  default     = {}
}

variable "data_collection_rule_associations" {
  type = map(object({
    name                         = optional(string)
    target_key                   = optional(string)
    target_resource_id           = optional(string)
    data_collection_rule_key     = optional(string)
    data_collection_rule_id      = optional(string)
    data_collection_endpoint_key = optional(string)
    data_collection_endpoint_id  = optional(string)
    description                  = optional(string)
  }))
  description = "Associations that attach DCRs and/or DCEs to explicitly supplied targets or known platform scopes."
  default     = {}

  validation {
    condition = alltrue([
      for item in values(var.data_collection_rule_associations) :
      (
        (try(item.target_key, null) != null || try(item.target_resource_id, null) != null) &&
        !(try(item.target_key, null) != null && try(item.target_resource_id, null) != null)
      )
    ])
    error_message = "Each DCR association must set exactly one of target_key or target_resource_id."
  }

  validation {
    condition = alltrue([
      for item in values(var.data_collection_rule_associations) :
      (try(item.data_collection_rule_key, null) != null || try(item.data_collection_rule_id, null) != null || try(item.data_collection_endpoint_key, null) != null || try(item.data_collection_endpoint_id, null) != null)
    ])
    error_message = "Each DCR association must set at least one DCR or DCE reference."
  }
}

variable "sentinel" {
  type = object({
    enabled = optional(bool, false)
    approved_data_connectors = optional(map(object({
      connector_type = string
      source         = optional(string)
      enabled        = optional(bool, false)
      notes          = optional(string)
    })), {})
  })
  description = "Microsoft Sentinel onboarding and approved data connector target-state contract."
  default     = {}
}

variable "resource_provider_registrations" {
  type = map(object({
    features = optional(map(object({
      registered = bool
    })), {})
  }))
  description = "Azure resource providers that must be explicitly registered for the platform subscription."
  default     = {}
}

variable "additional_lock_scopes" {
  type        = map(string)
  description = "Additional named scopes that can be referenced by management_locks or role_assignments."
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
  description = "Subscription and platform-resource RBAC assignments."
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

variable "subscription_activity_log_diagnostics" {
  type = object({
    name                           = string
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    logs = map(object({
      category = string
    }))
  })
  description = "Subscription activity-log export to the platform Log Analytics workspace and optional archive destinations."
  default     = null
}

variable "entra_diagnostic_settings" {
  type = object({
    name                           = string
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    logs = map(object({
      category = string
    }))
  })
  description = "Microsoft Entra diagnostic export. Requires tenant-level permissions."
  default     = null
}

variable "subscription_budgets" {
  type = map(object({
    amount     = number
    time_grain = string
    time_period = object({
      start_date = string
      end_date   = optional(string)
    })
    notifications = map(object({
      enabled        = optional(bool, true)
      threshold      = number
      operator       = string
      threshold_type = optional(string, "Actual")
      contact_emails = optional(list(string))
      contact_groups = optional(list(string))
      contact_roles  = optional(list(string))
    }))
  }))
  description = "Subscription-level FinOps budgets."
  default     = {}
}

variable "management_locks" {
  type = map(object({
    name       = string
    scope_key  = optional(string)
    scope      = optional(string)
    lock_level = string
    notes      = optional(string)
  }))
  description = "Management locks for critical platform resources."
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

variable "defender_plans" {
  type = map(object({
    resource_type = string
    tier          = string
    subplan       = optional(string)
    extensions = optional(map(object({
      name                            = string
      additional_extension_properties = optional(map(string))
    })), {})
  }))
  description = "Microsoft Defender for Cloud subscription pricing plans."
  default     = {}
}

variable "security_contact" {
  type = object({
    name                = optional(string, "default")
    email               = string
    phone               = optional(string)
    alert_notifications = optional(bool, true)
    alerts_to_admins    = optional(bool, true)
  })
  description = "Microsoft Defender for Cloud security contact."
  default     = null
}

variable "security_center_settings" {
  type = map(object({
    enabled = bool
  }))
  description = "Microsoft Defender for Cloud settings such as MCAS and WDATP."
  default     = {}
}

variable "defender_soc_posture" {
  type = object({
    enabled                       = optional(bool, false)
    defender_standard_enabled     = optional(bool, false)
    sentinel_enabled              = optional(bool, false)
    data_collection_rules_enabled = optional(bool, false)
    security_contact_enabled      = optional(bool, false)
    notes                         = optional(string)
  })
  description = "No-cost posture contract for Defender/SOC readiness. This documents intent without enabling paid Defender, Sentinel, or data-collection resources by default."
  default     = {}
}
