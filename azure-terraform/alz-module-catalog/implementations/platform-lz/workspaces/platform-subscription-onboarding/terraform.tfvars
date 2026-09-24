# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
# The azurerm provider reads both from those Terraform variables.
#

tfe_organization             = "Compeer-Financial-Services"
governance_workspace_name    = "platform-governance"
authorization_workspace_name = "platform-authorization"

onboarding = {
  enabled = true

  # Platform operations and security roles are assigned at enterprise/platform
  # MG scope by platform-authorization and inherited by these subscriptions.
  # Keep this empty unless a role is intentionally required on every onboarded
  # subscription and cannot be assigned once at the target MG. Privileged and
  # emergency access is managed through PIM/manual break-glass controls.
  baseline_role_assignments = {}

  # Subscription IDs are non-secret deployment configuration. Replace these
  # example GUIDs with the CSP-created IDs before a live apply.
  subscriptions = {}

  # Replace subscriptions = {} with this map after inserting real IDs:
  # subscriptions = {
  #   security = {
  #     subscription_id             = "11111111-1111-1111-1111-111111111111"
  #     target_management_group_key = "security-mg"
  #     display_name                = "sub-security-prod-cus"
  #     apply_baseline_rbac         = false
  #   }
  #   identity = {
  #     subscription_id             = "22222222-2222-2222-2222-222222222222"
  #     target_management_group_key = "identity-mg"
  #     display_name                = "sub-identity-prod-cus"
  #     apply_baseline_rbac         = false
  #   }
  #   management = {
  #     subscription_id             = "33333333-3333-3333-3333-333333333333"
  #     target_management_group_key = "management-mg"
  #     display_name                = "sub-management-prod-cus"
  #     apply_baseline_rbac         = false
  #   }
  #   connectivity = {
  #     subscription_id             = "44444444-4444-4444-4444-444444444444"
  #     target_management_group_key = "connectivity-mg"
  #     display_name                = "sub-connectivity-prod-cus"
  #     apply_baseline_rbac         = false
  #   }
  # }
}
