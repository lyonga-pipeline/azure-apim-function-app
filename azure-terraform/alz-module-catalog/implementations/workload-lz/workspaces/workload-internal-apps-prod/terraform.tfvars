# Ticket 204094 / NET-23.
# Set tenant_id, subscription_id, connectivity_subscription_id and
# private_dns_subscription_id in HCP Terraform, not as committed credentials.
tfe_organization            = "REPLACE_HCP_ORGANIZATION"
management_workspace_name   = "REPLACE_MANAGEMENT_WORKSPACE"
connectivity_workspace_name = "REPLACE_CONNECTIVITY_WORKSPACE"

spoke = {
  enabled                       = false
  appcode                       = "REPLACE_APPROVED_APPCODE"
  domain                        = "internal-apps"
  location                      = "centralus"
  address_space                 = ["REPLACE_IPAM_APPROVED_PROD_VNET_CIDR"]
  reserved_address_spaces       = []
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
  operations = {
    notification_emails = ["REPLACE_PRODUCTION_ONCALL_EMAIL"]
    action_group_ids    = []
    budget              = { amount = 0 } # REQUIRED: approved positive amount in billing currency.
  }
  monitoring = {
    sampling_percentage      = 100
    failed_request_threshold = 5 # Starting point; tune against the workload SLO.
    # Entra-authenticated HTTPS, routed through hub egress. For private-only
    # telemetry, first establish the centrally owned AMPLS/DNS path.
    internet_ingestion_enabled = true
    internet_query_enabled     = true
    private_link_ready         = false
  }
  # Add only Blob stores the application actually needs. The production profile
  # defaults each account to ZRS and 30-day Blob/container soft deletion.
  storage_accounts = {}
  # Existing VM IDs plus approved workload-subscription vault/policy; no empty
  # backup vault or compute is deployed by this common mixed-workload template.
  backup = null
}
