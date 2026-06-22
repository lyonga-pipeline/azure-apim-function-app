variable "subscription_id" {
  type        = string
  description = "NP1 workload subscription ID."
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID."
}

variable "location" {
  type        = string
  description = "Azure region for ClientSync np1 resources."
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

variable "names" {
  type = object({
    resource_group       = string
    identity             = string
    app_service_plan     = string
    storage_account      = string
    key_vault            = string
    application_insights = string
    function_app         = string
  })
}

variable "shared" {
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
      storage_queue = string
      storage_file  = string
    })
  })
}

variable "runtime_app_settings" {
  type        = map(string)
  description = "Deployment/runtime-owned app settings used for np1 validation. Keep infrastructure-owned settings in the pattern."
  default     = {}
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

variable "additional_tags" {
  type    = map(string)
  default = {}
}

