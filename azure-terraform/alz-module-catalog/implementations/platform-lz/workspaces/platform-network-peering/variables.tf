variable "tenant_id" {
  description = "Entra tenant ID. Provide via the shared HCP variable set as a Terraform-category variable named `tenant_id` - it is constant across the tenant. Do NOT set it in a .tfvars file or as an env var."
  type        = string
}

variable "hub_subscription_id" {
  description = "Connectivity/hub subscription ID (contains the hub VNet + Private DNS zones). Set as a workspace-level Terraform-category variable in HCP."
  type        = string
}

variable "spoke_subscription_id" {
  description = "Workload/spoke subscription ID (contains the spoke VNet). Set as a workspace-level Terraform-category variable in HCP."
  type        = string
}

variable "network_peering" {
  description = "Network peering workspace configuration."
  type        = any
  default = {
    enabled = false
  }
}
