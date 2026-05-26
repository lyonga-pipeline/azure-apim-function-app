variable "subscription_id" { type = string }
variable "tenant_id" { type = string }
variable "location" { type = string }

variable "environment" {
  type = string

  validation {
    condition     = contains(["np1", "np2", "np3", "prod"], var.environment)
    error_message = "environment must be np1, np2, np3, or prod."
  }
}

variable "application" {
  type = object({
    code                = string
    name                = string
    business_owner      = string
    cost_center         = string
    data_classification = string
    compliance_boundary = string
    source_repo         = string
  })
}

variable "resource_group" {
  type = object({
    name = string
  })
}

variable "shared" {
  description = "Environment-resolved shared infrastructure. These IDs are resolved at the app root, not inside base modules."
  type = object({
    log_analytics_workspace_id = string
    action_group_id            = string
    subnet_ids = object({
      app_integration  = string
      private_endpoint = string
    })
    private_dns_zone_ids = object({
      app_service   = string
      key_vault     = string
      storage_blob  = string
      storage_file  = string
      storage_queue = string
    })
  })
}

variable "identity" {
  type = object({
    name = string
  })
}

variable "key_vault" {
  type = object({
    name                       = string
    sku_name                   = string
    soft_delete_retention_days = number
    purge_protection_enabled   = bool
    contacts = optional(map(object({
      email = string
      name  = optional(string)
      phone = optional(string)
    })), {})
  })
}

variable "key_vault_secrets" {
  type = map(object({
    value           = string
    content_type    = optional(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    tags            = optional(map(string), {})
  }))
  default = {}
}

variable "storage_account" {
  type = object({
    name                     = string
    account_replication_type = string
    containers = map(object({
      container_access_type = optional(string, "private")
      metadata              = optional(map(string))
    }))
    queues = map(object({
      metadata = optional(map(string))
    }))
    shares = map(object({
      quota       = optional(number, 100)
      access_tier = optional(string)
      metadata    = optional(map(string))
    }))
  })
}

variable "app_service_plan" {
  type = object({
    name                         = string
    os_type                      = string
    sku_name                     = string
    worker_count                 = optional(number)
    maximum_elastic_worker_count = optional(number)
    zone_balancing_enabled       = optional(bool)
  })
}

variable "function_app" {
  type = object({
    name                        = string
    os_type                     = string
    functions_extension_version = string
    always_on                   = bool
    health_check_path           = string
    app_settings                = map(string)
    application_stack = object({
      dotnet_version              = optional(string)
      java_version                = optional(string)
      node_version                = optional(string)
      powershell_core_version     = optional(string)
      python_version              = optional(string)
      use_dotnet_isolated_runtime = optional(bool)
      use_custom_runtime          = optional(bool)
    })
  })
}

variable "diagnostics" {
  type = object({
    logs = map(object({
      category       = optional(string)
      category_group = optional(string)
    }))
    metrics = map(object({
      category = string
      enabled  = optional(bool, true)
    }))
  })
}

variable "alerts" {
  type = object({
    http_5xx_threshold = number
    severity           = number
    frequency          = string
    window_size        = string
  })
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}
