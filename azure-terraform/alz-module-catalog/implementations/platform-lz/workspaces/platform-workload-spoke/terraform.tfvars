# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
# The azurerm provider reads both from those Terraform variables.
#

location                    = "centralus"
environment                 = "prod"
tfe_organization            = "Compeer-Financial-Services"
management_workspace_name   = "platform-management"
connectivity_workspace_name = "platform-connectivity"

workload_tags = {
  application = "internal-apps"
  # No appcode set here on purpose - this workspace's workload_appcode
  # (below, currently unset) is the single source of truth for both this
  # tag and the naming module's appcode-based names; set workload_appcode,
  # not this, when this spoke gets scoped to one specific app.
  owner       = "Application Owner"
  source_repo = "ado://Compeer/internal-apps"
  created_on  = "2026-01-01"
  # NOT changed to tier-0: this is a workload spoke, not a platform
  # resource - tier-0 is reserved for foundational platform/enterprise
  # services (identity, networking, security tooling), not individual apps.
  criticality_tier    = "tier-2"
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
  # bronze/none) and would fail the new validation. Read as "bronze" - a
  # generic internal-apps spoke with no stated criticality above tier-2 -
  # this is my inference, not a confirmed decision; get this confirmed with
  # whoever owns this workload's actual DR requirement.
  dr_tier = "bronze"
  # expiration_date      = "2026-12-31"   # sandbox / temporary / POC only
}

# Single source of truth for this spoke's appcode - drives BOTH the
# workload_tags.appcode default above and the naming module's appcode-based
# resource names (Key Vault, storage accounts). 1-9 letters. Leave null for
# a spoke that isn't scoped to one specific app.
# workload_appcode = "orders"

workload_spoke = {
  enabled        = false
  resource_group = {}
  spoke_vnet = {
    address_space = ["10.10.0.0/16"]
    subnets = {
      app_integration   = { address_prefixes = ["10.10.1.0/24"] }
      private_endpoints = { address_prefixes = ["10.10.2.0/24"], private_endpoint_network_policies = "Disabled" }
    }
  }
  workload_identity = {
    enabled = false
  }
  workload_key_vault = {
    enabled = false
  }
}
