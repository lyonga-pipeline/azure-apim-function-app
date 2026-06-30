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

variable "hcp_oauth_token_id" {
  type        = string
  description = "HCP Terraform VCS OAuth token ID for the Azure DevOps connection."
  sensitive   = true

  validation {
    condition     = length(trimspace(var.hcp_oauth_token_id)) > 0
    error_message = "hcp_oauth_token_id must be provided."
  }
}

variable "policy_repo_identifier" {
  type        = string
  description = "HCP VCS repository identifier for the Azure DevOps repo that contains the OPA policy directory."

  validation {
    condition     = length(trimspace(var.policy_repo_identifier)) > 0
    error_message = "policy_repo_identifier must be provided in the format expected by the configured HCP VCS provider."
  }
}

variable "policy_repo_branch" {
  type        = string
  description = "Fallback VCS branch for the policy set when the catalog source_control branch is absent."
  default     = "main"
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
