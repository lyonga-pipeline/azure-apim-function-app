variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}

variable "execution_subscription_id" {
  description = "Subscription the provider authenticates against (any subscription the onboarding identity can use)."
  type        = string
}

variable "use_tfe_outputs" {
  description = "Read management group IDs from the governance workspace outputs instead of passing them in."
  type        = bool
  default     = true
}

variable "tfe_organization" {
  description = "HCP Terraform organization that contains the governance workspace."
  type        = string
  default     = null
}

variable "governance_workspace_name" {
  description = "Workspace that publishes management_group_ids."
  type        = string
  default     = "platform-governance"
}

variable "management_group_ids" {
  description = "Explicit management group ID catalog. Used when use_tfe_outputs = false, or merged over the governance outputs when both are present."
  type        = map(string)
  default     = {}
}

variable "onboarding" {
  description = "subscription-onboarding pattern configuration."
  type = object({
    enabled                   = optional(bool, false)
    root_management_group_id  = optional(string)
    default_tags              = optional(map(string), {})
    baseline_role_assignments = optional(any, {})
    subscriptions             = optional(any, {})
  })
  default = {}
}
