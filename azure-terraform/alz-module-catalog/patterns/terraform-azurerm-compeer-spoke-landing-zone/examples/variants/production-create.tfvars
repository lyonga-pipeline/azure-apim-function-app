# Opt-in extensions, NOT an instruction to activate deferred Phase 2 services in Phase 1.
# Review application SLOs, costs, telemetry egress/AMPLS and operational ownership first.
environment = "prod"
key_vault = {
  enabled  = true
  sku_name = "standard" # Premium only for a justified HSM-backed key requirement.
  secret_readers = {
    application_runtime = { principal_id = "88888888-8888-8888-8888-888888888888", principal_type = "ServicePrincipal" }
  }
  secret_officer_group_ids = { operators = "99999999-9999-9999-9999-999999999999" }
}
diagnostics = { enabled = true, existing_settings = {} }
storage_accounts = {
  data = {
    enabled = true
    # Null uses approved HCP naming + subscription uniqueness. Use an explicit name only if approved.
    name                       = null
    replication_type           = "ZRS" # Choose GZRS/RAGZRS if the approved DR architecture requires it.
    delete_retention_days      = 30
    grant_workload_blob_access = true # UAMI receives account-scoped Blob Data Contributor.
  }
  future_archive = { enabled = false, grant_workload_blob_access = false }
}
monitoring = {
  enabled                          = true
  create_application_insights      = true
  existing_application_insights    = null
  manage_existing_telemetry_access = false
  alerts_enabled                   = true
  create_failed_requests_alert     = true
  existing_failed_requests_alert   = null
  sampling_percentage              = 100
  failed_request_threshold         = 5 # Tune to the application's approved failed-request SLO.
  # Entra authentication is enforced. Public endpoints still require an approved egress path.
  internet_ingestion_enabled = true
  internet_query_enabled     = true
  private_link_ready         = false
}
operations = {
  create_action_group        = true # A DIFFERENT application on-call audience from the platform team.
  platform_action_group_keys = []
  action_group_ids           = []
  notification_emails        = ["orders-oncall@example.com"] # Replace; test notification delivery.
}
backup = null # Compute and backup policies are not created by this blueprint.
