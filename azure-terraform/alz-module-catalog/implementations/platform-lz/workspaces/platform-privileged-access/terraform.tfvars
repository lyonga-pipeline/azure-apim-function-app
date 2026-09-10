# Deployable tfvars for this workspace.
#
#   tenant_id       -> shared HCP variable set (Terraform category)
#   subscription_id -> this workspace's Terraform-category variable in HCP
#
# log_analytics_workspace_id and the AZ-*-Admins group object IDs are read from
# the platform-management and platform-authorization workspaces.

tfe_organization             = "Compeer-Financial-Services"
management_workspace_name    = "platform-management"
authorization_workspace_name = "platform-authorization"

privileged_access = {
  enabled = true

  # PIM ELIGIBLE assignments (no standing privilege). principal_group_key
  # resolves against platform-authorization group_object_ids.
  pim_eligible_role_assignments = {
    platform_admins_owner = {
      scope               = "/providers/Microsoft.Management/managementGroups/platform-mg"
      role_definition_id  = "/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" # Owner
      principal_group_key = "plt_admins"
      justification       = "Platform team Owner on platform-mg, PIM activation only."
      schedule            = { expiration = { duration_days = 365 } }
    }
    security_admins_security_admin = {
      scope               = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
      role_definition_id  = "/providers/Microsoft.Authorization/roleDefinitions/fb1c8493-542b-48eb-b624-b4c8fea62acd" # Security Admin
      principal_group_key = "sec_admins"
      justification       = "Security break-fix on Defender / policy."
      schedule            = { expiration = { duration_days = 365 } }
    }
    network_admins_network_contributor = {
      scope               = "/providers/Microsoft.Management/managementGroups/connectivity-mg"
      role_definition_id  = "/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7" # Network Contributor
      principal_group_key = "net_admins"
      justification       = "Network team hub changes."
      schedule            = { expiration = { duration_days = 365 } }
    }
  }

  # Break-glass accounts are NOT created by Terraform. This only alerts on them.
  break_glass_user_principal_names = [
    "emergency-01@compeer.onmicrosoft.com",
    "emergency-02@compeer.onmicrosoft.com",
  ]
  break_glass_alert = {
    enabled             = true
    name                = "break-glass-signin"
    resource_group_name = "rg-secops-alerts"
    location            = "centralus"
    severity            = 0
    action_group_ids    = [] # set to the SOC critical action group ID
  }

  tags = {
    managed_by = "terraform"
    component  = "privileged-access"
  }

  operational_contracts = {
    break_glass_accounts = {
      phase                = "Phase 2"
      owner                = "Identity"
      implementation_state = "manual-control"
      required_controls    = ["EMERGENCY-01/02 cloud-only", "Global Administrator", "excluded from all Conditional Access", "credentials split & sealed", "quarterly access test"]
      notes                = "Created / credentialed outside Terraform so tenant recovery survives broken IaC, identity-sync failure, or automation compromise. Microsoft guidance."
    }
    pim_activation_policy = {
      phase                = "Phase 2"
      owner                = "Identity"
      implementation_state = "provider-gap"
      required_controls    = ["require approval", "MFA on activation", "max 8h activation", "justification", "notification recipients"]
      evidence_locations   = ["Entra PIM > Azure resources > Settings"]
      notes                = "Eligible assignments are codified here; the per-role activation policy is set in the portal until provider coverage is approved."
    }
    admin_conditional_access = {
      phase                = "Phase 2"
      owner                = "Identity"
      implementation_state = "manual-control"
      required_controls    = ["block legacy auth", "phishing-resistant MFA for admins", "compliant / PAW device", "protect Azure management apps", "report-only first"]
      notes                = "Tenant-wide, high lockout risk; portal-managed with a report-only rollout."
    }
    secure_admin_environment = {
      phase                = "Phase 2 / Phase 4"
      owner                = "EUC / Platform"
      implementation_state = "external-system"
      required_controls    = ["PAW or dedicated secure AVD", "no Azure admin from daily workstation", "Intune device compliance enforced via CA"]
      notes                = "PAW / secure-AVD build and Intune compliance are owned by the endpoint team."
    }
  }
}
