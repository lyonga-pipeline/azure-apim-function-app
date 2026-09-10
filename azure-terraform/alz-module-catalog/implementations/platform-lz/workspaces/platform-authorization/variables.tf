variable "tenant_id" {
  description = "Entra tenant ID. Provide via the shared HCP variable set as a Terraform-category variable named `tenant_id`. Do NOT set it in a .tfvars file."
  type        = string
}

variable "subscription_id" {
  description = "A platform subscription for the azurerm provider (RBAC here is at management-group scope; any platform sub works). Set as a workspace-level Terraform-category variable in HCP."
  type        = string
}

variable "authorization" {
  description = <<-EOT
    Entra authorization foundation: rbac_groups, custom_role_definitions,
    role_assignments (the RBAC matrix), operational_contracts.
    See patterns/terraform-azurerm-compeer-platform-authorization.
  EOT
  type        = any
  default = {
    enabled = false
  }
}
