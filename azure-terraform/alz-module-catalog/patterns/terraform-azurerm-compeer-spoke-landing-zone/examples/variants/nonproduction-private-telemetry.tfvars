# Same security baseline; lower-cost resilience/telemetry defaults, not weaker private access.
# Use a separate non-prod subscription/state and an independently approved non-prod IPAM allocation.
environment      = "dev"
key_vault        = { enabled = true, sku_name = "standard" }
diagnostics      = { enabled = true, existing_settings = {} }
storage_accounts = { data = { enabled = true, replication_type = "LRS", delete_retention_days = 7, grant_workload_blob_access = false } }
monitoring = {
  enabled                      = true
  create_application_insights  = true
  alerts_enabled               = false
  create_failed_requests_alert = false
  sampling_percentage          = 20
  failed_request_threshold     = 20
  # Only use this variant AFTER the platform owner has attached the component to AMPLS
  # and validated private DNS, ingestion and query paths. This flag does not build AMPLS.
  internet_ingestion_enabled = false
  internet_query_enabled     = false
  private_link_ready         = true
}
operations = { create_action_group = false, platform_action_group_keys = [], action_group_ids = [], notification_emails = [] }
backup     = null
