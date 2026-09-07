variable "tenant_id" {
  description = "Entra tenant ID. Provide via the shared HCP variable set as a Terraform-category variable named `tenant_id` - it is constant across the tenant. Do NOT set it in a .tfvars file or as an env var."
  type        = string
}

variable "execution_subscription_id" {
  description = "Target subscription ID for this workspace. Set it directly as a workspace-level Terraform-category variable in HCP (it differs per landing zone). Do NOT set it in a .tfvars file."
  type        = string
}

variable "location" {
  description = "Default Azure region for policy assignments that need a managed identity."
  type        = string
  default     = "centralus"
}

variable "governance" {
  description = "Governance workspace configuration: management groups, policy, custom roles, RBAC, and MG budgets."
  type        = any
  default = {
    enabled           = false
    management_groups = {}
  }
}

variable "environment" {
  description = "Environment token, required by the naming module (MG names take the env from their key, not this)."
  type        = string
  default     = "prod"
}
