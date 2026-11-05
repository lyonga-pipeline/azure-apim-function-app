# SYNTHETIC REFERENCE ONLY: layer over baseline.tfvars; replaces the ENTIRE spoke object.
# sbx is an alias: resources and environment tags use the established sandbox token.
environment = "sbx"
spoke = {
  location                    = "centralus"
  appcode                     = "orders"
  domain                      = "internal-apps"
  address_space               = ["10.200.0.0/20"]
  reserved_address_spaces     = ["10.201.0.0/20", "10.40.0.0/16"]
  inspection_address_prefixes = ["10.40.0.0/16"]
  egress_next_hop_ip          = "10.102.0.4" # Replace with the approved hub NVA frontend.
  # Add approved private-endpoint/DNS access explicitly in each subnet's rules.
  # Keep this default, or select another existing map key (for example endpoints).
  private_endpoint_subnet_key = "private_endpoints"
  workload_tags = {
    application         = "orders"
    owner               = "Application Operations"
    source_repo         = "ado://example/workloads/orders-sandbox"
    created_on          = "2026-11-04"
    expiration_date     = "2027-02-04" # Approved cleanup date; required for sandbox AND sbx.
    criticality_tier    = "tier-3"
    data_classification = "confidential"
    lifecycle_state     = "temporary"
    cost_center         = "CC-0000"
    gl_category         = "cloud-infrastructure"
    dr_tier             = "none"
    additional_tags     = { support_team = "application-operations" }
  }
  # Logical purposes are extensible; naming generates sandbox-<purpose>-subnet.
  # Every entry receives the same NSG/UDR baseline. Add only reviewed application rules.
  subnets = {
    app               = { address_prefixes = ["10.200.0.0/24"] }
    data              = { address_prefixes = ["10.200.1.0/24"] }
    presentation      = { address_prefixes = ["10.200.2.0/24"] }
    private_endpoints = { address_prefixes = ["10.200.3.0/27"] }
  }
  workload_access_group_ids = {}
}
key_vault   = { enabled = true, sku_name = "standard", secret_readers = {}, secret_officer_group_ids = {} }
diagnostics = { enabled = true, existing_settings = {} }
storage_accounts = {
  data = { enabled = true, replication_type = "ZRS", delete_retention_days = 30, grant_workload_blob_access = false }
}
monitoring = { enabled = false, alerts_enabled = false }
operations = { create_action_group = false, notification_emails = [], action_group_ids = [], platform_action_group_keys = [] }
backup     = null
