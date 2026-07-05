variable "location" {
  type        = string
  description = "Azure region for all legacy app resources."
}

variable "environment" {
  type        = string
  description = "Environment key, such as np1."
}

variable "settings" {
  description = "Single large legacy contract that mixes naming, app config, security posture, and dependency settings."
  type = object({
    application = object({
      code           = string
      name           = string
      business_owner = string
      source_repo    = string
      tf_workspace   = string
    })
    names = object({
      resource_group       = string
      identity             = string
      app_service_plan     = string
      storage_account      = string
      key_vault            = string
      application_insights = string
      function_app         = string
    })
    tags = map(string)
    app_service_plan = object({
      os_type  = optional(string, "Windows")
      sku_name = optional(string, "Y1")
    })
    storage_account = object({
      account_replication_type      = optional(string, "LRS")
      shared_access_key_enabled     = optional(bool, true)
      public_network_access_enabled = optional(bool, true)
      allow_blob_public_access      = optional(bool, true)
      containers                    = optional(set(string), [])
      queues                        = optional(set(string), [])
    })
    key_vault = object({
      sku_name                      = optional(string, "standard")
      public_network_access_enabled = optional(bool, true)
      enable_rbac_authorization     = optional(bool, false)
      purge_protection_enabled      = optional(bool, false)
      soft_delete_retention_days    = optional(number, 7)
    })
    function_app = object({
      runtime_app_settings = optional(map(string), {})
      dotnet_version       = optional(string, "v8.0")
    })
  })
}
