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
  # Document v7, Section 6.1 / Figure 2. The map KEY is the Azure management group
  # name (matches the design doc verbatim); display_name is the portal label.
  # The existing legacy LZ (compeer-mg) is a separate tenant-root child and is
  # NOT recreated here. regulated-apps-* and shared-services-* are stood up but
  # dormant (no subscriptions / policy) until a distinct governance need arises.
  management_groups = {
    "compeer-enterprise-mg" = { display_name = "Compeer Enterprise", parent_key = "root" }

    "platform-mg"     = { display_name = "Platform", parent_key = "compeer-enterprise-mg" }
    "security-mg"     = { display_name = "Security", parent_key = "platform-mg" }
    "identity-mg"     = { display_name = "Identity", parent_key = "platform-mg" }
    "management-mg"   = { display_name = "Management", parent_key = "platform-mg" }
    "connectivity-mg" = { display_name = "Connectivity", parent_key = "platform-mg" }

    "workloads-mg"       = { display_name = "Workloads", parent_key = "compeer-enterprise-mg" }
    "internal-apps-mg"   = { display_name = "Internal Apps", parent_key = "workloads-mg" }
    "external-apps-mg"   = { display_name = "External Apps", parent_key = "workloads-mg" }
    "regulated-apps-mg"  = { display_name = "Regulated Apps (dormant)", parent_key = "workloads-mg" }
    "shared-services-mg" = { display_name = "Shared Services (dormant)", parent_key = "workloads-mg" }

    "sandbox-mg"        = { display_name = "Sandbox", parent_key = "compeer-enterprise-mg" }
    "decommissioned-mg" = { display_name = "Decommissioned", parent_key = "compeer-enterprise-mg" }

    "internal-apps-dev-mg"  = { display_name = "Internal Apps - Dev", parent_key = "internal-apps-mg" }
    "internal-apps-test-mg" = { display_name = "Internal Apps - Test", parent_key = "internal-apps-mg" }
    "internal-apps-uat-mg"  = { display_name = "Internal Apps - UAT", parent_key = "internal-apps-mg" }
    "internal-apps-prod-mg" = { display_name = "Internal Apps - Prod", parent_key = "internal-apps-mg" }

    "external-apps-dev-mg"  = { display_name = "External Apps - Dev", parent_key = "external-apps-mg" }
    "external-apps-test-mg" = { display_name = "External Apps - Test", parent_key = "external-apps-mg" }
    "external-apps-uat-mg"  = { display_name = "External Apps - UAT", parent_key = "external-apps-mg" }
    "external-apps-prod-mg" = { display_name = "External Apps - Prod", parent_key = "external-apps-mg" }

    "regulated-apps-dev-mg"  = { display_name = "Regulated Apps - Dev", parent_key = "regulated-apps-mg" }
    "regulated-apps-test-mg" = { display_name = "Regulated Apps - Test", parent_key = "regulated-apps-mg" }
    "regulated-apps-uat-mg"  = { display_name = "Regulated Apps - UAT", parent_key = "regulated-apps-mg" }
    "regulated-apps-prod-mg" = { display_name = "Regulated Apps - Prod", parent_key = "regulated-apps-mg" }

    "shared-services-dev-mg"  = { display_name = "Shared Services - Dev", parent_key = "shared-services-mg" }
    "shared-services-test-mg" = { display_name = "Shared Services - Test", parent_key = "shared-services-mg" }
    "shared-services-uat-mg"  = { display_name = "Shared Services - UAT", parent_key = "shared-services-mg" }
    "shared-services-prod-mg" = { display_name = "Shared Services - Prod", parent_key = "shared-services-mg" }
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
