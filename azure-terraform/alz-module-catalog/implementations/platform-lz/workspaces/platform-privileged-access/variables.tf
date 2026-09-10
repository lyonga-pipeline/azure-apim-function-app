variable "tenant_id" {
  description = "Entra tenant ID. Provide via the shared HCP variable set. Do NOT set it in a .tfvars file."
  type        = string
}

variable "subscription_id" {
  description = "SecOps / management subscription hosting the break-glass alert. Set as a workspace-level Terraform-category variable in HCP."
  type        = string
}

variable "use_tfe_outputs" {
  description = "Read approved outputs from the management and authorization workspaces."
  type        = bool
  default     = true
}

variable "tfe_organization" {
  description = "HCP Terraform organization that contains the producer workspaces."
  type        = string
  default     = null
}

variable "management_workspace_name" {
  description = "Workspace that publishes log_analytics_workspace_id."
  type        = string
  default     = "platform-management"
}

variable "authorization_workspace_name" {
  description = "Workspace that publishes group_object_ids for the AZ-*-Admins groups."
  type        = string
  default     = "platform-authorization"
}

variable "log_analytics_workspace_id" {
  description = "Explicit Log Analytics workspace ID. Overrides the management workspace output when set."
  type        = string
  default     = null
}

variable "privileged_access" {
  description = <<-EOT
    Privileged access configuration:
      pim_eligible_role_assignments  - map; each entry sets role_definition_id +
        scope, and either principal_id OR principal_group_key (an
        authorization workspace group_object_ids key).
      break_glass_user_principal_names, break_glass_alert, operational_contracts, tags.
    See patterns/terraform-azurerm-compeer-privileged-access.
  EOT
  type        = any
  default = {
    enabled = false
  }
}
