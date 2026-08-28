variable "subscription_id" {
  type        = string
  description = "Platform identity subscription id."
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant id. Leave null to use the tenant from the active Azure credentials."
  default     = null
}

variable "location" {
  type        = string
  description = "Azure region for identity resources."
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

variable "platform_identities" {
  type = map(object({
    name = string
  }))
  default = {}
}

variable "key_vault" {
  type = object({
    name                            = string
    sku_name                        = optional(string, "standard")
    soft_delete_retention_days      = optional(number, 90)
    purge_protection_enabled        = optional(bool, true)
    rbac_authorization_enabled      = optional(bool, true)
    enabled_for_deployment          = optional(bool, false)
    enabled_for_disk_encryption     = optional(bool, false)
    enabled_for_template_deployment = optional(bool, false)
    public_network_access_enabled   = optional(bool, false)
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
    network_acls = optional(object({
      default_action             = string
      bypass                     = string
      ip_rules                   = optional(list(string))
      virtual_network_subnet_ids = optional(list(string))
    }))
    contacts = optional(map(object({
      email = string
      name  = optional(string)
      phone = optional(string)
    })), {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  })
}

variable "identity_role_assignments" {
  type = map(object({
    name                                   = optional(string)
    identity_key                           = string
    scope                                  = optional(string)
    role_definition_name                   = optional(string)
    role_definition_id                     = optional(string)
    principal_type                         = optional(string, "ServicePrincipal")
    description                            = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    skip_service_principal_aad_check       = optional(bool)
    delegated_managed_identity_resource_id = optional(string)
  }))
  default = {}
}

variable "external_role_assignments" {
  type = map(object({
    name                                   = optional(string)
    scope                                  = string
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
  default = {}
}

variable "key_vault_private_endpoint" {
  type = object({
    name                 = string
    subnet_id            = string
    private_dns_zone_ids = list(string)
    edge_zone            = optional(string)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  })
  default = null
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Shared Log Analytics workspace ID for diagnostics. Leave null to skip Key Vault diagnostics until platform-management is available."
  default     = null
}

variable "diagnostics" {
  type = object({
    log_analytics_destination_type = optional(string)
    logs = optional(map(object({
      category       = optional(string)
      category_group = optional(string)
      })), {
      all_logs = {
        category_group = "allLogs"
      }
    })
    metrics = optional(map(object({
      category = string
      enabled  = optional(bool, true)
      })), {
      all_metrics = {
        category = "AllMetrics"
        enabled  = true
      }
    })
  })
  default = {}
}

variable "additional_lock_scopes" {
  type        = map(string)
  description = "Additional named scopes that can be referenced by management_locks."
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
  description = "Locks for critical platform identity resources."
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
