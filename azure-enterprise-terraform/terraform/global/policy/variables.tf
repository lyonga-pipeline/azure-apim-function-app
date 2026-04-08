variable "subscription_id" {
  type        = string
  description = "Execution subscription used for global policy deployment."
}

variable "management_groups_state_rg" {
  type        = string
  description = "Resource group hosting the management-groups state."
  default     = "rg-tfstate-dev"
}

variable "management_groups_state_sa" {
  type        = string
  description = "Storage account hosting the management-groups state."
  default     = "demotest822e"
}

variable "management_groups_state_container" {
  type        = string
  description = "Container hosting the management-groups state."
  default     = "deploy-container"
}

variable "management_groups_state_key" {
  type        = string
  description = "State blob key for the management-groups stack."
  default     = "global/management-groups.tfstate"
}

variable "management_groups_state_subscription_id" {
  type        = string
  description = "Subscription containing the management-groups remote state. Must be set explicitly — no default so that test/prod activations cannot silently inherit the dev platform subscription."

  validation {
    condition     = !can(regex("^0{8}-0{4}-0{4}-0{4}-0{12}$", var.management_groups_state_subscription_id))
    error_message = "management_groups_state_subscription_id still uses the all-zero placeholder. Set the real platform subscription id in tfvars."
  }
}

variable "root_management_group_id" {
  type        = string
  description = "Tenant root management group id used as the parent scope for shared policy definitions."
}

variable "organization_prefix" {
  type        = string
  description = "Short prefix used for policy resource names."
  default     = "fin"
}

variable "allowed_locations" {
  type        = list(string)
  description = "Allowed Azure regions."
}

variable "policy_assignment_location" {
  type        = string
  description = "Azure region used for the SystemAssigned managed identity on policy assignments. Required when any policy in the initiative uses deployIfNotExists or modify effect."
  default     = "eastus"
}

variable "required_tags" {
  type        = list(string)
  description = "Required enterprise tags enforced by the active policy initiatives. All resources in managed scopes must carry these tags or deployment is denied."
  default = [
    "env",
    "application",
    "created_by",
    "bt_owner",
    "source_repo",
    "tf_workspace",
    "recovery",
    "cost_center",
    "data_classification",
    "compliance_boundary",
  ]
}
