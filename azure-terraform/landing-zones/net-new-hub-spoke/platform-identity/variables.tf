variable "subscription_id" {
  type        = string
  description = "Platform identity subscription id."
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant id."
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
    name                       = string
    sku_name                   = optional(string, "standard")
    soft_delete_retention_days = optional(number, 90)
    purge_protection_enabled   = optional(bool, true)
    contacts = optional(map(object({
      email = string
      name  = optional(string)
      phone = optional(string)
    })), {})
  })
}

variable "identity_role_assignments" {
  type = map(object({
    identity_key         = string
    scope                = optional(string)
    role_definition_name = optional(string)
    role_definition_id   = optional(string)
    principal_type       = optional(string, "ServicePrincipal")
    description          = optional(string)
  }))
  default = {}
}

variable "external_role_assignments" {
  type = map(object({
    scope                = string
    principal_id         = string
    role_definition_name = optional(string)
    role_definition_id   = optional(string)
    principal_type       = optional(string)
    description          = optional(string)
  }))
  default = {}
}

variable "key_vault_private_endpoint" {
  type = object({
    name                 = string
    subnet_id            = string
    private_dns_zone_ids = list(string)
  })
  default = null
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Shared Log Analytics workspace ID for diagnostics."
}

variable "diagnostics" {
  type = object({
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
