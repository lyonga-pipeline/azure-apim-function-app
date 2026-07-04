variable "environment" {
  type        = string
  description = "Environment key, such as sandbox, np1, np2, np3, or prod."
}

variable "location" {
  type        = string
  description = "Azure region for resources created by this pattern."
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID used when creating Key Vault."
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
    terraform_workspace = string
    recovery_tier       = optional(string, "standard")
    additional_tags     = optional(map(string), {})
  })
}

variable "resource_group" {
  type = object({
    mode = string
    create = optional(object({
      name = string
    }))
    existing = optional(object({
      name = string
      id   = optional(string)
    }))
  })
}

variable "identity" {
  type = object({
    mode = string
    create = optional(object({
      name = string
    }))
    existing = optional(object({
      id           = string
      principal_id = string
      client_id    = optional(string)
    }))
  })
}

variable "app_service_plan" {
  type = object({
    mode = string
    create = optional(object({
      name                   = string
      os_type                = optional(string, "Windows")
      sku_name               = string
      worker_count           = optional(number)
      zone_balancing_enabled = optional(bool)
    }))
    existing = optional(object({
      id       = string
      name     = optional(string)
      os_type  = optional(string, "Windows")
      sku_name = optional(string)
    }))
  })
}

variable "storage_account" {
  type = object({
    mode = string
    create = optional(object({
      name                              = string
      account_replication_type          = optional(string, "LRS")
      shared_access_key_enabled         = optional(bool, false)
      public_network_access_enabled     = optional(bool, false)
      infrastructure_encryption_enabled = optional(bool, true)
      network_rules = optional(object({
        default_action             = string
        bypass                     = optional(list(string), ["AzureServices"])
        ip_rules                   = optional(list(string), [])
        virtual_network_subnet_ids = optional(list(string), [])
      }))
      blob_properties = optional(object({
        versioning_enabled              = optional(bool, true)
        change_feed_enabled             = optional(bool, true)
        delete_retention_days           = optional(number, 30)
        container_delete_retention_days = optional(number, 30)
      }))
    }))
    existing = optional(object({
      id   = string
      name = string
    }))
    containers = optional(map(object({
      container_access_type = optional(string, "private")
      metadata              = optional(map(string))
    })), {})
    queues = optional(map(object({
      metadata = optional(map(string))
    })), {})
    shares = optional(map(object({
      quota       = optional(number, 100)
      access_tier = optional(string)
      metadata    = optional(map(string))
    })), {})
  })
}

variable "key_vault" {
  type = object({
    mode = string
    create = optional(object({
      name                       = string
      sku_name                   = optional(string, "standard")
      soft_delete_retention_days = optional(number, 90)
      purge_protection_enabled   = optional(bool, true)
      contacts = optional(map(object({
        email = string
        name  = optional(string)
        phone = optional(string)
      })), {})
    }))
    existing = optional(object({
      id        = string
      name      = string
      vault_uri = string
    }))
    secrets = optional(map(object({
      value           = string
      content_type    = optional(string)
      not_before_date = optional(string)
      expiration_date = optional(string)
      tags            = optional(map(string), {})
    })), {})
  })
}

variable "application_insights" {
  type = object({
    mode = string
    create = optional(object({
      name                          = string
      application_type              = optional(string, "web")
      local_authentication_disabled = optional(bool, true)
      retention_in_days             = optional(number, 90)
    }))
    existing = optional(object({
      id                = string
      connection_string = string
    }))
  })
}

variable "function_app" {
  type = object({
    name                              = string
    os_type                           = optional(string, "Windows")
    functions_extension_version       = optional(string, "~4")
    always_on                         = optional(bool, true)
    health_check_eviction_time_in_min = optional(number)
    health_check_path                 = optional(string)
    infrastructure_app_settings       = optional(map(string), {})
    runtime_app_settings              = optional(map(string), {})
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

variable "network" {
  type = object({
    app_service_integration_subnet_id = optional(string)
  })
  default = {}
}

variable "private_endpoints" {
  type = object({
    enabled   = optional(bool, true)
    subnet_id = optional(string)
    targets = optional(object({
      function_app  = optional(bool, true)
      key_vault     = optional(bool, true)
      storage_blob  = optional(bool, true)
      storage_queue = optional(bool, true)
      storage_file  = optional(bool, false)
    }), {})
    private_dns_zone_ids = optional(object({
      app_service   = optional(string)
      key_vault     = optional(string)
      storage_blob  = optional(string)
      storage_queue = optional(string)
      storage_file  = optional(string)
    }), {})
  })
  default = {}
}

variable "diagnostics" {
  type = object({
    enabled                    = optional(bool, true)
    log_analytics_workspace_id = optional(string)
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

variable "role_assignments" {
  type = object({
    enabled = optional(bool, true)
    additional = optional(map(object({
      scope                = string
      principal_id         = string
      role_definition_name = optional(string)
      role_definition_id   = optional(string)
      principal_type       = optional(string)
      description          = optional(string)
    })), {})
  })
  default = {}
}

variable "alerts" {
  type = object({
    enabled            = optional(bool, true)
    action_group_id    = optional(string)
    severity           = optional(number, 3)
    frequency          = optional(string, "PT5M")
    window_size        = optional(string, "PT5M")
    http_5xx_threshold = optional(number, 10)
  })
  default = {}
}
