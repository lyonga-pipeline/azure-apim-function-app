variable "subscription_id" {
  type        = string
  description = "Shared-services subscription ID."
}

variable "tenant_id" {
  type        = string
  description = "Microsoft Entra tenant ID."
  default     = null
}

variable "location" {
  type        = string
  description = "Azure region for shared-services resources."
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

variable "spoke_vnet" {
  type        = any
  description = "Shared-services VNet and subnet model. Uses the same reusable contract as the workload-spoke pattern."
}

variable "network_security_groups" {
  type    = any
  default = {}
}

variable "subnet_nsg_associations" {
  type    = any
  default = {}
}

variable "route_tables" {
  type    = any
  default = {}
}

variable "subnet_route_table_associations" {
  type    = any
  default = {}
}

variable "hub_connection" {
  type    = any
  default = null
}

variable "private_dns_zone_links" {
  type    = any
  default = {}
}

variable "platform_identity" {
  type = object({
    enabled = optional(bool, false)
    name    = optional(string)
  })
  default = {}
}

variable "platform_key_vault" {
  type    = any
  default = {}
}

variable "role_assignments" {
  type    = any
  default = {}
}

variable "management_locks" {
  type    = any
  default = {}
}

variable "diagnostic_settings" {
  type    = any
  default = {}
}

variable "additional_scopes" {
  type    = map(string)
  default = {}
}
