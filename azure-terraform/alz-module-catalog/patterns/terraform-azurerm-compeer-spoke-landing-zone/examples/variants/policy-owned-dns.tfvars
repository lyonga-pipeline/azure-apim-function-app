# New spokes only until the documented existing-state DNS ownership handoff is complete.
# baseline.tfvars supplies synthetic network, tags and access; this object replaces its platform object.
private_endpoint_dns_mode        = "policy"
policy_dns_registration_approved = false # Set true only after central policies, zone RBAC and forwarding are verified.
platform = {
  management_contract_version   = "0.1.0"
  connectivity_contract_version = "0.1.0"
  log_analytics_workspace_id    = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
  hub_virtual_network_id        = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
  hub_address_space             = ["10.102.0.0/21"]
  dns_server_ips                = ["10.102.0.10", "10.102.0.11"]
}
key_vault        = { enabled = true, sku_name = "standard", secret_readers = {}, secret_officer_group_ids = {} }
storage_accounts = { data = { enabled = true, replication_type = "ZRS", delete_retention_days = 30, grant_workload_blob_access = true } }
diagnostics      = { enabled = true, existing_settings = {} }
monitoring       = { enabled = false, alerts_enabled = false }
operations       = {}
backup           = null
