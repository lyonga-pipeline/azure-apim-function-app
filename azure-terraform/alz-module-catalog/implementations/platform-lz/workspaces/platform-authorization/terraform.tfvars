# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
#
# Run identity needs: Entra directory write (group creation) + User Access
# Administrator at compeer-enterprise-mg. See IDENTITY-RBAC-IAC-BOUNDARY.md.

authorization = {
  enabled = true

  # Entra security groups — the ONLY principals granted Azure RBAC.
  # User -> Group -> Role -> Scope. Membership is governed by identity lifecycle
  # (see operational_contracts.access_lifecycle), not asserted here.
  rbac_groups = {
    plt_readers      = { display_name = "AZ-PLT-Readers", description = "Read-only across platform-mg." }
    plt_contributors = { display_name = "AZ-PLT-Contributors", description = "Contributor on platform-mg." }
    plt_admins       = { display_name = "AZ-PLT-Admins", description = "Owner on platform-mg (PIM-eligible only).", assignable_to_role = true }

    sec_readers   = { display_name = "AZ-SEC-Readers", description = "Security reader, enterprise scope." }
    sec_operators = { display_name = "AZ-SEC-Operators", description = "Security operations on Defender / Sentinel." }
    sec_admins    = { display_name = "AZ-SEC-Admins", description = "Security admin (PIM-eligible only).", assignable_to_role = true }

    net_readers   = { display_name = "AZ-NET-Readers", description = "Read-only on connectivity-mg." }
    net_operators = { display_name = "AZ-NET-Operators", description = "Network Contributor on connectivity-mg." }
    net_admins    = { display_name = "AZ-NET-Admins", description = "Network admin (PIM-eligible only).", assignable_to_role = true }

    audit_readers = { display_name = "AZ-AUDIT-Readers", description = "Read-only across the enterprise MG for audit evidence." }
  }

  # RBAC Assignment Matrix (standing, least-privilege). Admin/Owner roles are NOT
  # here — they are PIM-eligible only (platform-privileged-access).
  role_assignments = {
    plt_readers_platform       = { scope = "/providers/Microsoft.Management/managementGroups/platform-mg", group_key = "plt_readers", role_definition_name = "Reader" }
    plt_contributors_platform  = { scope = "/providers/Microsoft.Management/managementGroups/platform-mg", group_key = "plt_contributors", role_definition_name = "Contributor" }
    net_readers_connectivity   = { scope = "/providers/Microsoft.Management/managementGroups/connectivity-mg", group_key = "net_readers", role_definition_name = "Reader" }
    net_operators_connectivity = { scope = "/providers/Microsoft.Management/managementGroups/connectivity-mg", group_key = "net_operators", role_definition_name = "Network Contributor" }
    sec_readers_enterprise     = { scope = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg", group_key = "sec_readers", role_definition_name = "Security Reader" }
    sec_operators_enterprise   = { scope = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg", group_key = "sec_operators", role_definition_name = "Security Admin" }
    audit_readers_enterprise   = { scope = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg", group_key = "audit_readers", role_definition_name = "Reader" }
  }

  custom_role_definitions = {}

  operational_contracts = {
    break_glass_accounts = {
      phase                = "Phase 1"
      owner                = "Identity"
      implementation_state = "manual-control"
      required_controls    = ["EMERGENCY-01/02 cloud-only", "Global Administrator", "excluded from all Conditional Access", "credentials split & sealed", "sign-in alert"]
      evidence_locations   = ["Entra > Users", "platform-privileged-access break_glass_alert", "break-glass runbook"]
      notes                = "IAM-04. Outside Terraform so tenant access survives broken IaC / identity-sync / automation compromise. Microsoft guidance."
    }
    cloud_only_admin_accounts = {
      phase                = "Phase 1 / Phase 2"
      owner                = "Identity"
      implementation_state = "external-system"
      required_controls    = ["AZADM-<name> per admin", "cloud-only, not AD-synced", "no mailbox", "phishing-resistant MFA", "multiple methods"]
      evidence_locations   = ["Entra > Users", "IGA joiner records"]
      notes                = "Account objects + credential/method registration provisioned via the identity lifecycle (IGA). RBAC granted through the groups above + PIM, never directly."
    }
    conditional_access = {
      phase                = "Phase 2"
      owner                = "Identity"
      implementation_state = "manual-control"
      required_controls    = ["block legacy auth", "phishing-resistant MFA for admins", "compliant/PAW device", "protect Azure management apps", "report-only before enforce"]
      evidence_locations   = ["Entra > Conditional Access", "report-only sign-in logs"]
      notes                = "IAM-08 is tenant-wide with high lockout blast radius. Portal-managed with a report-only rollout; validate before any future Graph import."
    }
    pim_activation_policy = {
      phase                = "Phase 2"
      owner                = "Identity"
      implementation_state = "provider-gap"
      required_controls    = ["approval workflow", "MFA on activation", "max activation duration", "notification recipients"]
      evidence_locations   = ["Entra PIM > Settings"]
      notes                = "platform-privileged-access creates eligible assignments; activation-policy settings reconciled in the portal until provider coverage is approved."
    }
    access_lifecycle = {
      phase                = "Phase 1 / Phase 10"
      owner                = "Identity"
      implementation_state = "external-system"
      required_controls    = ["joiner/mover/leaver automation", "monthly privileged access review", "quarterly RBAC certification", "annual admin group recertification"]
      evidence_locations   = ["IGA workflows", "Entra access reviews"]
      notes                = "Group membership and periodic reviews are governed by Entra ID Governance / IGA. Terraform owns the group + role objects only."
    }
  }
}
