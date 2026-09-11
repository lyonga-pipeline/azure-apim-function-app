variable "tenant_id" {
  description = "Entra tenant ID. Provide via the shared HCP variable set as a Terraform-category variable named `tenant_id` - it is constant across the tenant. Do NOT set it in a .tfvars file or as an env var."
  type        = string
}

variable "execution_subscription_id" {
  description = "Target subscription ID for this workspace. Set it directly as a workspace-level Terraform-category variable in HCP (it differs per landing zone). Do NOT set it in a .tfvars file."
  type        = string
}

variable "use_tfe_outputs" {
  description = "Read management group IDs and group object IDs from upstream workspace outputs instead of passing them in."
  type        = bool
  default     = true
}

variable "tfe_organization" {
  description = "HCP Terraform organization that contains the governance and authorization workspaces."
  type        = string
  default     = null
}

variable "governance_workspace_name" {
  description = "Workspace that publishes management_group_ids."
  type        = string
  default     = "platform-governance"
}

variable "authorization_workspace_name" {
  description = "Workspace that publishes group_object_ids."
  type        = string
  default     = "platform-authorization"
}

variable "management_group_ids" {
  description = "Explicit management group ID catalog. Used when use_tfe_outputs = false, or merged over the governance outputs when both are present."
  type        = map(string)
  default     = {}
}

variable "group_object_ids" {
  description = "Explicit Entra security group object ID catalog keyed by platform-authorization rbac_groups key. Used when use_tfe_outputs = false, or merged over authorization outputs when both are present."
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
