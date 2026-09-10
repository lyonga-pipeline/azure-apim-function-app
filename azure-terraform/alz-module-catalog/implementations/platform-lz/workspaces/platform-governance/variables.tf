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
  description = <<-EOT
    Governance workspace configuration: management groups, policy, custom roles, RBAC, and MG budgets.
    management_groups keys ARE the Azure management group names and match the design
    doc (Section 6.1) verbatim — e.g. "compeer-enterprise-mg", "internal-apps-uat-mg".
    parent_key = "root" places a group under root_management_group_id / the tenant root.
  EOT
  type        = any
  default = {
    enabled           = false
    management_groups = {}
  }
}
