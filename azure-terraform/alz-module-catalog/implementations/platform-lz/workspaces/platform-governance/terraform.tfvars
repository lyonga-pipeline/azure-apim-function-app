# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
# The azurerm provider reads both from those Terraform variables.
#

location = "centralus"

governance = {
  enabled = true

  # Target management group hierarchy — Azure Landing Zone Architecture & Design
  # Document v7, Section 6.1 / Figure 2 / Appendix F. The map KEY is the Azure
  # management group name AND its display name (Appendix F gives one value per MG,
  # and that is what the Figure 2 boxes show) — display_name defaults to the key,
  # so it is left unset here.
  # The legacy LZ (compeer-mg) is a separate tenant-root child, NOT recreated here.
  # regulated-apps-* and shared-services-* are stood up but dormant (no
  # subscriptions / policy) until a distinct governance need arises.
  management_groups = {
    "compeer-enterprise-mg" = { parent_key = "root" }

    "platform-mg"     = { parent_key = "compeer-enterprise-mg" }
    "security-mg"     = { parent_key = "platform-mg" }
    "identity-mg"     = { parent_key = "platform-mg" }
    "management-mg"   = { parent_key = "platform-mg" }
    "connectivity-mg" = { parent_key = "platform-mg" }

    "workloads-mg"       = { parent_key = "compeer-enterprise-mg" }
    "internal-apps-mg"   = { parent_key = "workloads-mg" }
    "external-apps-mg"   = { parent_key = "workloads-mg" }
    "regulated-apps-mg"  = { parent_key = "workloads-mg" } # dormant
    "shared-services-mg" = { parent_key = "workloads-mg" } # dormant

    "sandbox-mg"        = { parent_key = "compeer-enterprise-mg" }
    "decommissioned-mg" = { parent_key = "compeer-enterprise-mg" }

    "internal-apps-dev-mg"  = { parent_key = "internal-apps-mg" }
    "internal-apps-test-mg" = { parent_key = "internal-apps-mg" }
    "internal-apps-uat-mg"  = { parent_key = "internal-apps-mg" }
    "internal-apps-prod-mg" = { parent_key = "internal-apps-mg" }

    "external-apps-dev-mg"  = { parent_key = "external-apps-mg" }
    "external-apps-test-mg" = { parent_key = "external-apps-mg" }
    "external-apps-uat-mg"  = { parent_key = "external-apps-mg" }
    "external-apps-prod-mg" = { parent_key = "external-apps-mg" }

    "regulated-apps-dev-mg"  = { parent_key = "regulated-apps-mg" }
    "regulated-apps-test-mg" = { parent_key = "regulated-apps-mg" }
    "regulated-apps-uat-mg"  = { parent_key = "regulated-apps-mg" }
    "regulated-apps-prod-mg" = { parent_key = "regulated-apps-mg" }

    "shared-services-dev-mg"  = { parent_key = "shared-services-mg" }
    "shared-services-test-mg" = { parent_key = "shared-services-mg" }
    "shared-services-uat-mg"  = { parent_key = "shared-services-mg" }
    "shared-services-prod-mg" = { parent_key = "shared-services-mg" }
  }

  # Deny/audit baseline (runbook §2.4). Starts in Audit - promote to Deny per
  # policy after the false-positive review and once the exemption path
  # (platform-policy workspace) is live.
  policy_baseline = {
    enabled              = true
    management_group_key = "compeer-enterprise-mg"
    effect               = "Audit"
    enforce              = true
    allowed_locations    = ["centralus", "eastus2"] # eastus2 = future DR
    # required_tag_names defaults to the platform-tags frozen key set
    assign_security_benchmark = true

    # Documented exception path: RGs carved out of deny-public-PaaS /
    # secure-storage. Resources here still get diagnostics + Defender - they
    # just don't trip the public-network-access deny. Keep this short + reviewed;
    # the Palo bootstrap storage should normally use a service endpoint instead
    # and NOT need this.
    exempt_resource_group_names = [
      # "rg-conn-palo-bootstrap",
    ]
  }
}
