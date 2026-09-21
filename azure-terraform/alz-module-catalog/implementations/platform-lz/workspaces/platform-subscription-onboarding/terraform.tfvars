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
  enabled                  = true
  root_management_group_id = "Compeer-Financial-Services" # tenant root group

  default_tags = {
    managed_by = "terraform"
  }

  # Platform operations and security roles are assigned at enterprise/platform
  # MG scope by platform-authorization and inherited by these subscriptions.
  # Keep this empty unless a role is intentionally required on every onboarded
  # subscription and cannot be assigned once at the target MG. Privileged and
  # emergency access is managed through PIM/manual break-glass controls.
  baseline_role_assignments = {}

  # Populate after CSP creates real subscription GUIDs. App/workload team access
  # should use principal_group_key when the group is created by
  # platform-authorization, or principal_id + principal_type = "Group" for a
  # pre-existing workload group owned by the client's IGA process.
  subscriptions = {}

  # Populate per subscription, found by reviewing it in the Portal before/
  # during onboarding: legacy policy ASSIGNMENTS made directly at the
  # subscription or a resource group (not inherited from an MG - those are
  # handled automatically when the subscription moves MG above). Two-phase:
  # add an entry + apply (imports it, no-op), then remove the entry + apply
  # (destroys it). See the pattern README's "Legacy policy removal" section.
  # Example:
  # legacy_policy_removals = {
  #   old_tag_policy = {
  #     subscription_key     = "<a key in subscriptions above>"
  #     scope_type            = "subscription"
  #     assignment_name       = "<assignment name from the Portal>"
  #     policy_definition_id  = "/providers/Microsoft.Authorization/policyDefinitions/<guid>"
  #   }
  # }
  legacy_policy_removals = {}
}
