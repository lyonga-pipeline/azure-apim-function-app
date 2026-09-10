variable "tenant_id" {
  description = "Entra tenant ID. Provide via the shared HCP variable set as a Terraform-category variable named `tenant_id`. Do NOT set it in a .tfvars file."
  type        = string
}

variable "subscription_id" {
  description = "A platform subscription for the azurerm provider. Set as a workspace-level Terraform-category variable in HCP."
  type        = string
}

variable "workload_identity" {
  description = <<-EOT
    Federated workload identities: workload_identities (app + SP + FICs + SP RBAC)
    and operational_contracts.
    See patterns/terraform-azurerm-compeer-workload-identity.
  EOT
  type        = any
  default = {
    enabled = false
  }
}
