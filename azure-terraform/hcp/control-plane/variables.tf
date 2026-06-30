variable "hcp_hostname" {
  type        = string
  description = "HCP Terraform or Terraform Enterprise hostname."
  default     = "app.terraform.io"
}

variable "hcp_organization" {
  type        = string
  description = "HCP Terraform organization that owns the policy set."

  validation {
    condition     = length(trimspace(var.hcp_organization)) > 0
    error_message = "hcp_organization must be provided."
  }
}

variable "policy_source_root_path" {
  type        = string
  description = "Path from this Terraform root to the checked-out repository root that contains the catalog's policy directory."
  default     = "../../.."
}

variable "policy_scope_catalog_path" {
  type        = string
  description = "Path to the YAML catalog that declares HCP policy-set source and scopes."
  default     = "../policy-scope-catalog.yaml"
}

variable "policy_set_key" {
  type        = string
  description = "Key under policy_sets in the policy scope catalog to deploy."
  default     = "net_new_lz_opa"
}

variable "policy_set_name" {
  type        = string
  description = "Name of the HCP Terraform policy set to create or update."
  default     = "compeer-net-new-lz-opa"
}

variable "project_scopes" {
  type        = list(string)
  description = "Optional HCP project names to attach the policy set to. Overrides project_scopes from the catalog when non-empty."
  default     = []
}

variable "workspace_scopes" {
  type        = list(string)
  description = "Optional HCP workspace names to attach the policy set to. Overrides workspace_scopes from the catalog when non-empty."
  default     = []
}

variable "excluded_workspaces" {
  type        = list(string)
  description = "Optional HCP workspace names to exclude from the policy set. Overrides excluded_workspaces from the catalog when non-empty."
  default     = []
}

variable "manage_policy_set_content" {
  type        = bool
  description = "When true, create/update the policy set and upload local policy content. When false, attach an existing policy set by policy_set_name."
  default     = false
}

variable "opa_policy_tool_version" {
  type        = string
  description = "OPA runtime version to pin for the HCP policy set. Leave null to let HCP choose the default on creation."
  default     = null
}

variable "mandatory_policy_overridable" {
  type        = bool
  description = "Allow HCP users with policy override permission to override mandatory OPA policy failures."
  default     = true
}
