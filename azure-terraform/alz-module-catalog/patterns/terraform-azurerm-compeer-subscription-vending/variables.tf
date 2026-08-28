variable "subscription_id" {
  type        = string
  description = "Execution subscription used by the Terraform run identity."
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant/directory ID used by the Terraform run identity."
  default     = null
}

variable "vending_enabled" {
  type        = bool
  description = "Global safety switch. Set to true only when the billing scope and management group catalog have been reviewed."
  default     = false
}

variable "default_billing_scope_id" {
  type        = string
  description = "Default Azure billing scope used for subscription creation. A per-subscription billing_scope_id overrides this value."
  default     = null
}

variable "billing_account_name" {
  type        = string
  description = "Microsoft Customer Agreement billing account name from the Azure portal. Used with billing_profile_name and invoice_section_name to build default_billing_scope_id."
  default     = null
}

variable "billing_profile_name" {
  type        = string
  description = "Microsoft Customer Agreement billing profile name from the Azure portal."
  default     = null
}

variable "invoice_section_name" {
  type        = string
  description = "Microsoft Customer Agreement invoice section name from the Azure portal."
  default     = null
}

variable "default_tags" {
  type        = map(string)
  description = "Tags applied to all vended subscriptions unless overridden per subscription."
  default     = {}
}

variable "management_groups" {
  type = map(object({
    display_name        = optional(string)
    parent_key          = optional(string)
    management_group_id = optional(string)
    enabled             = optional(bool, true)
  }))
  description = "Management group catalog keyed by the architecture name. The root references existing management groups and normalizes names to Azure resource IDs."
  default     = {}
}

variable "subscriptions" {
  type = map(object({
    subscription_name    = optional(string)
    alias                = optional(string)
    billing_scope_id     = optional(string)
    management_group_key = string
    workload             = optional(string, "Production")
    enabled              = optional(bool, true)
    tags                 = optional(map(string), {})
  }))
  description = "Subscriptions to vend and place under the target management group."
  default     = {}
}

variable "subscription_role_assignments" {
  type = map(object({
    name                                   = optional(string)
    subscription_key                       = string
    principal_id                           = string
    role_definition_name                   = optional(string)
    role_definition_id                     = optional(string)
    principal_type                         = optional(string)
    description                            = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    skip_service_principal_aad_check       = optional(bool)
    delegated_managed_identity_resource_id = optional(string)
    enabled                                = optional(bool, true)
  }))
  description = "Optional subscription-scope RBAC assignments for vended subscriptions. Use group or managed identity principals; avoid direct user assignment for enterprise workloads."
  default     = {}

  validation {
    condition = alltrue([
      for item in values(var.subscription_role_assignments) :
      try(item.enabled, true) ? (
        (try(item.role_definition_name, null) != null || try(item.role_definition_id, null) != null) &&
        !(try(item.role_definition_name, null) != null && try(item.role_definition_id, null) != null)
      ) : true
    ])
    error_message = "Each enabled subscription_role_assignments entry must set exactly one of role_definition_name or role_definition_id."
  }
}

variable "subscription_timeouts" {
  type = object({
    create = optional(string, "90m")
    read   = optional(string, "30m")
    update = optional(string, "90m")
    delete = optional(string, "90m")
  })
  description = "Operation timeouts for Azure subscription alias creation and lifecycle operations."
  default     = {}
}
