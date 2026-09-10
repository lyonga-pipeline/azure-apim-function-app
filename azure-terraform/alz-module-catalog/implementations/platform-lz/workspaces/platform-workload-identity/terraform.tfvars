# Deployable tfvars for this workspace.
#
#   tenant_id       -> shared HCP variable set (Terraform category)
#   subscription_id -> this workspace's Terraform-category variable in HCP
#
# Run identity needs: Application Administrator (or Application.ReadWrite.OwnedBy)
# + User Access Administrator at compeer-enterprise-mg for the SP role assignments.
#
# 20 federated credentials per app registration. The platform uses a few SPs
# split by permission scope, NOT one per workspace.

workload_identity = {
  enabled = true

  workload_identities = {
    platform_control_plane = {
      display_name = "platform-compeer-control-plane-oidc"
      description  = "HCP Terraform OIDC identity for control-plane workspaces (governance, policy, authorization)."
      federated_credentials = {
        governance_plan     = { display_name = "hcp-governance-plan", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-governance:run_phase:plan" }
        governance_apply    = { display_name = "hcp-governance-apply", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-governance:run_phase:apply" }
        policy_plan         = { display_name = "hcp-policy-plan", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-policy:run_phase:plan" }
        policy_apply        = { display_name = "hcp-policy-apply", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-policy:run_phase:apply" }
        authorization_plan  = { display_name = "hcp-authorization-plan", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-authorization:run_phase:plan" }
        authorization_apply = { display_name = "hcp-authorization-apply", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-authorization:run_phase:apply" }
        privaccess_plan     = { display_name = "hcp-privileged-access-plan", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-privileged-access:run_phase:plan" }
        privaccess_apply    = { display_name = "hcp-privileged-access-apply", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-privileged-access:run_phase:apply" }
      }
      azure_role_assignments = {
        enterprise_contributor = { scope = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg", role_definition_name = "Management Group Contributor" }
        enterprise_uaa         = { scope = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg", role_definition_name = "User Access Administrator", description = "Create RBAC matrix assignments." }
      }
    }

    platform_networking = {
      display_name = "platform-compeer-networking-oidc"
      description  = "HCP Terraform OIDC identity for connectivity / hybrid-connectivity / peering / palo-alto workspaces."
      federated_credentials = {
        connectivity_plan  = { display_name = "hcp-connectivity-plan", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-connectivity:run_phase:plan" }
        connectivity_apply = { display_name = "hcp-connectivity-apply", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-connectivity:run_phase:apply" }
        hybrid_plan        = { display_name = "hcp-hybrid-connectivity-plan", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-hybrid-connectivity:run_phase:plan" }
        hybrid_apply       = { display_name = "hcp-hybrid-connectivity-apply", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-hybrid-connectivity:run_phase:apply" }
        peering_plan       = { display_name = "hcp-network-peering-plan", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-network-peering:run_phase:plan" }
        peering_apply      = { display_name = "hcp-network-peering-apply", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-network-peering:run_phase:apply" }
        palo_plan          = { display_name = "hcp-palo-alto-plan", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-palo-alto:run_phase:plan" }
        palo_apply         = { display_name = "hcp-palo-alto-apply", issuer = "https://app.terraform.io", subject = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-palo-alto:run_phase:apply" }
      }
      azure_role_assignments = {
        connectivity_contributor = { scope = "/providers/Microsoft.Management/managementGroups/connectivity-mg", role_definition_name = "Contributor" }
      }
    }
  }

  operational_contracts = {
    hcp_variable_set_wiring = {
      phase                = "Phase 4"
      owner                = "Platform"
      implementation_state = "codified"
      required_controls    = ["TFC_AZURE_PROVIDER_AUTH=true (env)", "TFC_AZURE_RUN_CLIENT_ID per workspace (env)", "ARM_TENANT_ID (env)", "tenant_id (Terraform category, shared set)"]
      evidence_locations   = ["platform-iac-foundation workspace"]
      notes                = "application_client_ids are wired to HCP workspace variables by platform-iac-foundation."
    }
    github_actions_oidc = {
      phase                = "Phase 4"
      owner                = "Platform"
      implementation_state = "external-system"
      required_controls    = ["repo/environment-scoped subject", "environment protection rules", "no long-lived PAT"]
      notes                = "GitHub side of any Actions federation (environments, required reviewers) is configured in GitHub."
    }
    no_secret_attestation = {
      phase                = "Phase 10"
      owner                = "Security"
      implementation_state = "external-system"
      required_controls    = ["no clientSecret / password credential on any platform app", "quarterly review of federated subjects", "stale SP detection"]
      notes                = "OIDC removes secrets; the recurring attestation that none were added is a governance review."
    }
  }
}
