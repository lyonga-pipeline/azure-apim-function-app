variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the policy deployment identity."
  type        = string
}

variable "execution_subscription_id" {
  description = "Subscription used by the provider for policy operations."
  type        = string
}

variable "location" {
  description = "Default Azure region for policy assignments that need a managed identity."
  type        = string
  default     = "centralus"
}

variable "use_tfe_outputs" {
  description = "Read approved governance outputs from HCP Terraform."
  type        = bool
  default     = true
}

variable "tfe_organization" {
  description = "HCP Terraform organization that contains the producer workspaces."
  type        = string
  default     = null
}

variable "governance_workspace_name" {
  description = "Workspace that publishes management_group_ids."
  type        = string
  default     = "platform-governance"
}

variable "management_group_ids" {
  description = "Explicit management group IDs. These override or extend governance workspace outputs."
  type        = map(string)
  default     = {}
}

variable "policy" {
  description = "Policy workspace configuration: definitions, initiatives, and assignments."
  type        = any
  default = {
    enabled = false
  }
}
