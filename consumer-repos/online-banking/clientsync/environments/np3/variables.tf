variable "subscription_id" {
  type        = string
  description = "NP3 workload subscription ID."
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID."
}

variable "location" {
  type        = string
  description = "Azure region for ClientSync np3 resources."
}

variable "environment" {
  type        = string
  description = "ClientSync environment key."
  default     = "np3"

  validation {
    condition     = var.environment == "np3"
    error_message = "This root is only for the ClientSync np3 environment."
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
}

variable "resource_group" {
  type        = any
  description = "Resource group pattern input for this ClientSync environment."
}

variable "identity" {
  type        = any
  description = "Managed identity pattern input for this ClientSync environment."
}

variable "app_service_plan" {
  type        = any
  description = "App Service plan pattern input for this ClientSync environment."
}

variable "storage_account" {
  type        = any
  description = "Storage account and child resource pattern input for this ClientSync environment."
}

variable "key_vault" {
  type        = any
  description = "Key Vault pattern input for this ClientSync environment. Secrets are passed separately through key_vault_secrets."
}

variable "application_insights" {
  type        = any
  description = "Application Insights pattern input for this ClientSync environment."
}

variable "function_app" {
  type        = any
  description = "Function App pattern input for this ClientSync environment."
}

variable "network" {
  type        = any
  description = "Network integration pattern input for this ClientSync environment."
}

variable "private_endpoints" {
  type        = any
  description = "Private endpoint pattern input for this ClientSync environment."
}

variable "diagnostics" {
  type        = any
  description = "Diagnostic settings pattern input for this ClientSync environment."
}

variable "role_assignments" {
  type        = any
  description = "Role assignment pattern input for this ClientSync environment."
}

variable "alerts" {
  type        = any
  description = "Monitor alert pattern input for this ClientSync environment."
}
