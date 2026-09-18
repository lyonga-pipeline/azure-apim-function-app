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

platform_tags = {
  application = "alz-platform-identity"
  # Same short code the naming module's disc_abbr uses for this component
  # (identity -> id) for the pattern's keyed resources, so the tag matches
  # the actual name prefix. (The pattern's own single Key Vault name uses a
  # separate "platform" appcode workaround for the naming module's singular
  # key_vault output specifically - see that pattern's naming.tf comment -
  # this tag intentionally tracks the conceptually-correct component
  # discriminator, not that workaround.)
  appcode     = "id"
  owner       = "Cloud Enablement"
  source_repo = "ado://Compeer/landing-zone"
  # created_on intentionally NOT set here - this workspace's root main.tf
  # owns it via a time_static resource (computed once on first apply,
  # stable across every later plan) and supersedes any value set here.
  # Platform tier-0: foundational enterprise/platform service (identity, key
  # management) required for other systems.
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

identity = {
  enabled        = true
  resource_group = {}
  # names from the naming module: <key>-<region>-<env>-id
  platform_identities = {
    automation = {}
  }
  key_vault = {
    sku_name                   = "standard"
    soft_delete_retention_days = 90
    purge_protection_enabled   = true
    contacts                   = {}
  }
  key_vault_private_endpoint_from_connectivity = {
    enabled = false
  }
  diagnostics = {
    logs = {
      audit = { category = "AuditEvent" }
    }
    metrics = {
      all = { category = "AllMetrics" }
    }
  }
}
