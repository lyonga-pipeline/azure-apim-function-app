variable "tenant_id" {
  description = "Entra tenant ID. Provide via the shared HCP variable set as a Terraform-category variable named `tenant_id` - it is constant across the tenant. Do NOT set it in a .tfvars file or as an env var."
  type        = string
}

variable "execution_subscription_id" {
  description = "Target subscription ID for this workspace. Set it directly as a workspace-level Terraform-category variable in HCP (it differs per landing zone). Do NOT set it in a .tfvars file."
  type        = string
}

variable "use_tfe_outputs" {
  description = "Read management group IDs from the governance workspace outputs."
  type        = bool
  default     = true
}

variable "tfe_organization" {
  description = "HCP Terraform organization that contains the producer workspaces."
  type        = string
}

variable "governance_workspace_name" {
  description = "Workspace that publishes management_group_ids."
  type        = string
  default     = "platform-governance"
}

variable "subscription_vending" {
  description = "Subscription vending workspace configuration."
  type        = any
  default = {
    enabled         = false
    vending_enabled = false
    subscriptions   = {}
  }
}
