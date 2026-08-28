variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the subscription vending identity."
  type        = string
}

variable "execution_subscription_id" {
  description = "Subscription used by the provider for subscription vending operations."
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
