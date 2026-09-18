# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
#   Cloudflare API token -> CLOUDFLARE_API_TOKEN (env) in the shared variable set
#

location                    = "centralus"
environment                 = "prod"
tfe_organization            = "Compeer-Financial-Services"
management_workspace_name   = "platform-management"
connectivity_workspace_name = "platform-connectivity"

platform_tags = {
  application = "alz-platform-cloudflare-connectors"
  # Same short code the naming module's abbr map uses for this component
  # (cloudflare-connectors -> cfc), so the tag matches the actual name prefix.
  appcode     = "cfc"
  owner       = "Cloud Enablement"
  source_repo = "ado://Compeer/landing-zone"
  # created_on intentionally NOT set here - this workspace's root main.tf
  # owns it via a time_static resource (computed once on first apply,
  # stable across every later plan) and supersedes any value set here.
  # Platform tier-0: foundational enterprise/platform service (enterprise
  # integration backbone) required for other systems.
  criticality_tier    = "tier-0"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "CC-0000"
  gl_category         = "cloud-infrastructure"
  # optional / conditional - set where you have a value
  # application_component = "..."
  # modified_on           = "2026-01-01"
  # created_by intentionally omitted - defaults to "Terraform" now (accurate:
  # this workspace IS how the resource gets created), replacing the old
  # additional_tags workaround below.
  # dr_tier: "standard" isn't one of the doc's four values (gold/silver/
  # bronze/none) and would fail the new validation. Read as "silver" - this
  # is my inference, not a confirmed decision; get this confirmed with
  # whoever owns the actual DR posture.
  dr_tier = "silver"
  # expiration_date      = "2026-12-31"   # sandbox / temporary / POC only
}

cloudflare_connectors = {
  enabled = false

  resource_group = {}

  connectors = {}

  operational_contracts = {
    connector_runtime = {
      enabled              = false
      implementation_state = "contract-only"
      required_controls    = ["approved cloudflared install path", "Palo Alto connector-to-origin policy", "tunnel health evidence"]
      notes                = "Terraform deploys connector VM infrastructure only unless an approved extension or image process is supplied."
    }
  }
}

admin_passwords              = {}
custom_data_by_key           = {}
extension_protected_settings = {}
