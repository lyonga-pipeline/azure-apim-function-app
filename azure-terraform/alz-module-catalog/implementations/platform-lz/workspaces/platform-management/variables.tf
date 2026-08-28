variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the management workspace."
  type        = string
}

variable "subscription_id" {
  description = "Management subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region for management resources."
  type        = string
  default     = "centralus"
}

variable "environment" {
  description = "Environment label used in names and tags."
  type        = string
  default     = "prod"
}

variable "platform_tags" {
  description = "Enterprise tag contract for management resources."
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

variable "management" {
  description = "Platform management workspace configuration."
  type        = any
  default = {
    enabled = false
  }
}
