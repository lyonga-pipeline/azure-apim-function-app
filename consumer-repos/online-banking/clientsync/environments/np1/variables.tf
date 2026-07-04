variable "subscription_id" {
  type        = string
  description = "NP1 workload subscription ID."
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID. Leave null when HCP Terraform Azure dynamic credentials provide the tenant."
  default     = null
  nullable    = true
}

variable "location" {
  type        = string
  description = "Azure region for ClientSync np1 resources."
  default     = "eastus"
}

variable "environment" {
  type        = string
  description = "ClientSync environment key."
  default     = "np1"

  validation {
    condition     = var.environment == "np1"
    error_message = "This root is only for the ClientSync np1 environment."
  }
}

variable "key_vault_secrets" {
  type = map(object({
    value           = string
    content_type    = optional(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    tags            = optional(map(string), {})
  }))
  default   = {}
  sensitive = true
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
  default = {
    code                = "clientsync"
    name                = "ClientSync"
    business_owner      = "Digital Banking"
    cost_center         = "CC-1001"
    data_classification = "confidential"
    compliance_boundary = "finserv"
    source_repo         = "ado://Compeer/online-banking"
    terraform_workspace = "lz-workload-clientsync-np1"
    recovery_tier       = "standard"
    additional_tags = {
      deployment_model = "function-app-composition-pattern"
      environment_type = "nonprod"
      pattern_pilot    = "function-app"
      pilot_workload   = "true"
    }
  }
}

variable "resource_group" {
  type        = any
  description = "Resource group pattern input for this ClientSync environment."
  default = {
    mode = "create"
    create = {
      name = "rg-clientsync-np1-app"
    }
  }
}

variable "identity" {
  type        = any
  description = "Managed identity pattern input for this ClientSync environment."
  default = {
    mode = "create"
    create = {
      name = "id-clientsync-np1-app"
    }
  }
}

variable "app_service_plan" {
  type        = any
  description = "App Service plan pattern input for this ClientSync environment."
  default = {
    mode = "create"
    create = {
      name                   = "asp-clientsync-np1-001"
      os_type                = "Windows"
      sku_name               = "Y1"
      worker_count           = null
      zone_balancing_enabled = null
    }
  }
}

variable "storage_account" {
  type        = any
  description = "Storage account and child resource pattern input for this ClientSync environment."
  default = {
    mode = "create"
    create = {
      name                          = "stclientsyncnp1001"
      account_replication_type      = "LRS"
      shared_access_key_enabled     = true
      public_network_access_enabled = true
      network_rules = {
        default_action = "Allow"
        bypass         = ["AzureServices"]
      }
      blob_properties = {
        versioning_enabled              = true
        change_feed_enabled             = true
        delete_retention_days           = 7
        container_delete_retention_days = 7
      }
    }
    containers = {
      payloads = {
        container_access_type = "private"
      }
      deadletter = {
        container_access_type = "private"
      }
    }
    queues = {
      inbound = {}
      poison  = {}
    }
    shares = {}
  }
}

variable "key_vault" {
  type        = any
  description = "Key Vault pattern input for this ClientSync environment. Secrets are passed separately through key_vault_secrets."
  default = {
    mode = "create"
    create = {
      name                       = "kv-clientsync-np1-001"
      sku_name                   = "standard"
      soft_delete_retention_days = 7
      purge_protection_enabled   = false
      contacts                   = {}
    }
  }
}

variable "application_insights" {
  type        = any
  description = "Application Insights pattern input for this ClientSync environment."
  default = {
    mode = "create"
    create = {
      name                          = "appi-clientsync-np1-001"
      application_type              = "web"
      local_authentication_disabled = true
      retention_in_days             = 30
    }
  }
}

variable "function_app" {
  type        = any
  description = "Function App pattern input for this ClientSync environment."
  default = {
    name                              = "func-clientsync-np1-001"
    os_type                           = "Windows"
    functions_extension_version       = "~4"
    always_on                         = false
    health_check_eviction_time_in_min = 10
    health_check_path                 = "/api/health"
    infrastructure_app_settings       = {}
    runtime_app_settings = {
      CLIENTSYNC_MODE = "NP1"
    }
    application_stack = {
      dotnet_version              = "v8.0"
      use_dotnet_isolated_runtime = true
    }
  }
}

variable "network" {
  type        = any
  description = "Network integration pattern input for this ClientSync environment."
  default     = {}
}

variable "private_endpoints" {
  type        = any
  description = "Private endpoint pattern input for this ClientSync environment."
  default = {
    enabled = false
  }
}

variable "diagnostics" {
  type        = any
  description = "Diagnostic settings pattern input for this ClientSync environment."
  default = {
    enabled = false
  }
}

variable "role_assignments" {
  type        = any
  description = "Role assignment pattern input for this ClientSync environment."
  default = {
    enabled    = true
    additional = {}
  }
}

variable "alerts" {
  type        = any
  description = "Monitor alert pattern input for this ClientSync environment."
  default = {
    enabled = false
  }
}
