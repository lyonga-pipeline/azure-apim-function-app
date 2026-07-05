variable "subscription_id" {
  type        = string
  description = "Legacy app np1 subscription ID. Leave null when HCP Terraform Azure dynamic credentials provide the subscription."
  default     = null
  nullable    = true
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID. Leave null when HCP Terraform Azure dynamic credentials provide the tenant."
  default     = null
  nullable    = true
}

variable "location" {
  type        = string
  description = "Azure region for legacy app np1 resources."
  default     = "eastus"
}

variable "environment" {
  type        = string
  description = "Legacy app environment key."
  default     = "np1"

  validation {
    condition     = var.environment == "np1"
    error_message = "This root is only for the legacy-app np1 environment."
  }
}

variable "legacy_app" {
  type        = any
  description = "Large legacy module input. Intentionally broad to demonstrate tight lifecycle coupling and weak policy boundaries."
}
