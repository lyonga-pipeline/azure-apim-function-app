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
  description = "Optional HCP project names to attach the policy set to. Leave empty to keep the policy set unattached to projects."
  default     = []
}

variable "workspace_scopes" {
  type        = list(string)
  description = "Optional HCP workspace names to attach the policy set to. Leave empty to keep the policy set unattached to workspaces."
  default     = []
}

variable "excluded_workspaces" {
  type        = list(string)
  description = "Optional HCP workspace names to exclude from the policy set."
  default     = []
}

variable "policy_content_mode" {
  type        = string
  description = "How to manage policy content. Use individual to create one OPA policy and attach it to the policy set, none to attach an existing policy set only, or slug to upload the full policy directory."
  default     = "individual"

  validation {
    condition     = contains(["individual", "none", "slug"], var.policy_content_mode)
    error_message = "policy_content_mode must be one of: individual, none, slug."
  }
}

variable "opa_policy_name" {
  type        = string
  description = "Name of the individual OPA policy to create and attach when policy_content_mode is individual."
  default     = "net-new-landing-zone-guardrails"
}

variable "opa_policy_description" {
  type        = string
  description = "Description of the individual OPA policy."
  default     = "Plan-time guardrails for Compeer net-new landing-zone HCP workspaces."
}

variable "opa_policy_query" {
  type        = string
  description = "OPA query for the individual policy."
  default     = "data.compeer.lz.deny"
}

variable "opa_policy_file_path" {
  type        = string
  description = "Path from the repository root to the bundled Rego file for the individual OPA policy."
  default     = "azure-terraform/policies/opa/policies/terraform_plan.rego"
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
