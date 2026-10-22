# Synthetic IDs and names: replace with approved existing resources before enabling.
# No credentials, PATs, secret values, certificates or private key material belong here.
enabled             = false
deployment_approved = false
subscription_id     = "11111111-1111-1111-1111-111111111111"
tenant_id           = "11111111-1111-1111-1111-111111111111"
resource_group_name = "orders-cus-prod-security-rg"
location            = "centralus"
environment         = "prod"
appcode             = "orders"
domain              = "internal-apps"
name                = "orders-cus-prod-vault" # Replace with an approved globally unique name.
sku_name            = "standard"

# Existing subnet and centrally owned zone; DNS links/forwarding belong to networking.
private_endpoints = {
  default = {
    subnet_id           = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/orders-prod/subnets/private-endpoints"
    private_dns_zone_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  }
}
network_access = {
  mode                    = "private"
  trusted_services_bypass = false
}

# Existing platform workspace, not its workspace GUID. Audit coverage is mandatory.
log_analytics_workspace_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
diagnostics = {
  enabled = true
  # Keep null for the legacy platform AzureDiagnostics table routing.
  # Set Dedicated only after updating SOC queries to the resource-specific schema.
  log_analytics_destination_type = null
}

# Entra OBJECT IDs of approved existing managed identities/groups, not client IDs.
secret_readers = {
  application = {
    principal_id   = "44444444-4444-4444-4444-444444444444"
    principal_type = "ServicePrincipal"
  }
}
secret_officer_group_ids = {}
data_access              = {}
keys                     = {}
monitoring               = { enabled = false }
timeouts                 = { create = "30m", read = "5m", update = "30m", delete = "30m" }

# Equivalent to the shared tagging module's output; keep created_on stable.
tags = {
  application         = "orders"
  appcode             = "orders"
  environment         = "prod"
  owner               = "Applications"
  source_repo         = "ado://REPLACE_ORGANIZATION/REPLACE_PROJECT/REPLACE_REPOSITORY"
  created_on          = "2026-10-22"
  created_by          = "Terraform"
  criticality_tier    = "tier-2"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "REPLACE_APPROVED_COST_CENTER"
  gl_category         = "cloud-infrastructure"
  dr_tier             = "silver"
}
