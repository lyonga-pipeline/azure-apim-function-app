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
  application         = "internal-apps"
  owner               = "Application Owner"
  source_repo         = "ado://Compeer/internal-apps"
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
