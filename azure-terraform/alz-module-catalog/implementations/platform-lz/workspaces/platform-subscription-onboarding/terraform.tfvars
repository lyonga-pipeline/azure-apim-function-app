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

  # Replace subscriptions = {} with this reviewed platform-build map after
  # inserting real IDs. This root places subscriptions into the v13 management
  # groups only; resource-group shape stays in the resource-owning roots
  # (including the one-RG internal-apps direction from the design doc/current
  # decision).
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
  #   sandbox_ops = {
  #     subscription_id             = "55555555-5555-5555-5555-555555555555"
  #     target_management_group_key = "sandbox-mg"
  #     display_name                = "sandbox-ops-sub"
  #     apply_baseline_rbac         = false
  #   }
  #   sandbox_developer = {
  #     subscription_id             = "66666666-6666-6666-6666-666666666666"
  #     target_management_group_key = "sandbox-mg"
  #     display_name                = "sandbox-developer-sub"
  #     apply_baseline_rbac         = false
  #   }
  #   sandbox_data = {
  #     subscription_id             = "77777777-7777-7777-7777-777777777777"
  #     target_management_group_key = "sandbox-mg"
  #     display_name                = "sandbox-data-sub"
  #     apply_baseline_rbac         = false
  #   }
  #   sandbox_architect = {
  #     subscription_id             = "88888888-8888-8888-8888-888888888888"
  #     target_management_group_key = "sandbox-mg"
  #     display_name                = "sandbox-architect-sub"
  #     apply_baseline_rbac         = false
  #   }
  #   pilot_internal_apps_prod = {
  #     subscription_id             = "99999999-9999-9999-9999-999999999999"
  #     target_management_group_key = "internal-apps-prod-mg"
  #     display_name                = "sub-workload-<pilot>-prod-cus"
  #     apply_baseline_rbac         = false
  #   }
  #   pilot_internal_apps_dev = {
  #     subscription_id             = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  #     target_management_group_key = "internal-apps-dev-mg"
  #     display_name                = "sub-workload-<pilot>-dev-cus"
  #     apply_baseline_rbac         = false
  #   }
  # }
}
