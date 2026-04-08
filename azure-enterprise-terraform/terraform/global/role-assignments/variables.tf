variable "subscription_id" {
  type        = string
  description = "Execution subscription used for global RBAC deployment."
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

variable "platform_deployer_principal_id" {
  type        = string
  description = "Principal id for the platform deployment pipeline."
  default     = ""
}

variable "security_reader_principal_id" {
  type        = string
  description = "Principal id for the security reader group or identity."
  default     = ""
}

variable "security_deployer_principal_id" {
  type        = string
  description = "Principal id for the security deployment identity."
  default     = ""
}

variable "nonprod_workload_deployer_principal_id" {
  type        = string
  description = "Principal id for the nonprod workload deployment identity."
  default     = ""
}

variable "prod_workload_deployer_principal_id" {
  type        = string
  description = "Principal id for the prod workload deployment identity."
  default     = ""
}

variable "prod_workload_reader_principal_id" {
  type        = string
  description = "Principal id for a read-only prod workload identity."
  default     = ""
}
