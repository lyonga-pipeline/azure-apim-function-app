# Ticket 204094 / NET-23.
# Set tenant_id, subscription_id, connectivity_subscription_id and
# private_dns_subscription_id in HCP Terraform, not as committed credentials.
tfe_organization            = "REPLACE_HCP_ORGANIZATION"
management_workspace_name   = "REPLACE_MANAGEMENT_WORKSPACE"
connectivity_workspace_name = "REPLACE_CONNECTIVITY_WORKSPACE"
governance_workspace_name   = "REPLACE_GOVERNANCE_WORKSPACE"

spoke = {
  enabled                 = false
  appcode                 = "REPLACE_APPROVED_APPCODE"
  domain                  = "internal-apps"
  location                = "centralus"
  address_space           = ["REPLACE_IPAM_APPROVED_PROD_VNET_CIDR"]
  reserved_address_spaces = []
  # Complete approved remote prefixes before enabling; hub prefixes are automatic.
  # inspection_address_prefixes = ["REPLACE_IDENTITY_ONPREM_OTHER_SPOKE_CIDRS"]
  egress_next_hop_ip            = "REPLACE_APPROVED_HUB_NVA_IP"
  allow_azure_provided_dns      = false
  manage_hub_attachment         = true
  gateway_transit_enabled       = false
  private_endpoint_client_cidrs = []
  workload_tags = {
    application         = "REPLACE_APPLICATION"
    owner               = "REPLACE_ACCOUNTABLE_TEAM"
    source_repo         = "ado://REPLACE/WORKLOAD_REPOSITORY"
    criticality_tier    = "tier-2"
    data_classification = "confidential"
    lifecycle_state     = "active"
    cost_center         = "REPLACE_COST_CENTER"
    gl_category         = "cloud-infrastructure"
    dr_tier             = "silver"
  }
  subnets = {
    application = {
      address_prefixes = ["REPLACE_IPAM_APPROVED_APPLICATION_SUBNET"]
      rules            = {}
    }
    private_endpoints = {
      address_prefixes = ["REPLACE_IPAM_APPROVED_PRIVATE_ENDPOINT_SUBNET"]
    }
  }
  key_vault = {
    sku_name                 = "standard"
    secret_readers           = {}
    secret_officer_group_ids = {}
  }
  workload_access_group_ids = {}
  # ON HOLD: OBS-09 and OBS-04 are Phase 2. R3.4 coverage is still a go-live
  # gate; activation needs workload/SOC approval, SLOs, recipients and a tested
  # network path. These examples are intentionally commented out, not deployed.
  # monitoring = {
  #   enabled                    = true
  #   alerts_enabled             = true
  #   sampling_percentage        = 100
  #   failed_request_threshold   = 5
  #   internet_ingestion_enabled = true
  #   internet_query_enabled     = true
  #   private_link_ready         = false
  # }
  # operations = {
  #   notification_emails = ["REPLACE_PRODUCTION_ONCALL_EMAIL"]
  #   action_group_ids    = []
  #   # Budget remains in the governance subscription baseline. Only enable
  #   # after handing ownership to this state; never create a second owner.
  #   budget = { enabled = true, amount = 0 } # Replace with approved positive amount.
  # }
  # ON HOLD: WKL-05 data services until an actual workload requirement is approved.
  # storage_accounts = { data = {} } # Production: ZRS, 30-day soft deletion.
  # Existing compute + approved same-subscription RSV/policy are prerequisites.
  # backup = { recovery_vault_id = "REPLACE", backup_policy_id = "REPLACE", virtual_machines = { app = "REPLACE" } }
}
