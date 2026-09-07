# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
# The azurerm provider reads both from those Terraform variables.
#

tfe_organization          = "Compeer-Financial-Services"
governance_workspace_name = "platform-governance"

subscription_vending = {
  enabled                  = true
  vending_enabled          = false
  default_billing_scope_id = null
  default_tags = {
    managed_by = "terraform"
  }
  subscriptions = {
    platform_security     = { subscription_name = "platform-security-sub", management_group_key = "security", workload = "Production" }
    platform_identity     = { subscription_name = "platform-identity-sub", management_group_key = "identity", workload = "Production" }
    platform_management   = { subscription_name = "platform-management-sub", management_group_key = "management", workload = "Production" }
    platform_connectivity = { subscription_name = "platform-connectivity-sub", management_group_key = "connectivity", workload = "Production" }
    sandbox_ops           = { subscription_name = "sandbox-ops-sub", management_group_key = "sandbox", workload = "DevTest" }
  }
}
