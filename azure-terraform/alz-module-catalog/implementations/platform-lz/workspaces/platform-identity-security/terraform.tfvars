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
  application         = "alz-platform-identity"
  owner               = "Cloud Enablement"
  source_repo         = "ado://Compeer/landing-zone"
  created_on          = "2026-01-01"
  criticality_tier    = "tier-2"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "CC-0000"
  gl_category         = "cloud-infrastructure"
  # optional / conditional - set where you have a value
  # application_component = "..."
  # modified_on           = "2026-01-01"
  # created_by            = "terraform"
  dr_tier = "standard"
  # expiration_date      = "2026-12-31"   # sandbox / temporary / POC only
  additional_tags = {
    created_by = "terraform"
  }
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
