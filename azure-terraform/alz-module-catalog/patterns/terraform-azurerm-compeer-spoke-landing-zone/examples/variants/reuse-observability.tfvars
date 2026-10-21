# Reuse APPROVED same-application/environment telemetry, alert and contact routes.
# Sharing a LAW does not imply sharing an Application Insights component across unrelated apps.
# Diagnostic reuse assumes these parent resources ALREADY belong to this Terraform state,
# while another approved owner manages their diagnostic settings. No automatic import occurs.
environment      = "prod"
key_vault        = { enabled = true, sku_name = "standard" }
storage_accounts = { data = { enabled = true, name = "exampleordprddb01", replication_type = "ZRS", delete_retention_days = 30, grant_workload_blob_access = false } }
monitoring = {
  enabled                     = true
  create_application_insights = false
  existing_application_insights = {
    id           = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/components/orders-prod"
    workspace_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
  }
  manage_existing_telemetry_access = false # External owner grants publishing rights; opt in only by agreement.
  alerts_enabled                   = true
  create_failed_requests_alert     = false
  existing_failed_requests_alert = {
    id                      = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/metricAlerts/orders-failed-requests"
    application_insights_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/components/orders-prod"
    action_group_ids        = ["/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/platform"]
  }
}
# Existing alert already owns routing. No new contacts/routes or duplicate rule.
operations = { create_action_group = false, platform_action_group_keys = [], action_group_ids = [], notification_emails = [] }
diagnostics = {
  enabled = false # Turn off Terraform diagnostic creation; required audit coverage stays on.
  existing_settings = {
    key_vault = {
      id                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-prod-security-rg/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault/providers/Microsoft.Insights/diagnosticSettings/external-audit"
      workspace_id      = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      log_categories    = ["AuditEvent"]
      metric_categories = ["AllMetrics"]
    }
    "storage.data.account" = {
      id                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-prod-data-rg/providers/Microsoft.Storage/storageAccounts/exampleordprddb01/providers/Microsoft.Insights/diagnosticSettings/external-metrics"
      workspace_id      = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      log_categories    = []
      metric_categories = ["AllMetrics"]
    }
    "storage.data.blob" = {
      id                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-prod-data-rg/providers/Microsoft.Storage/storageAccounts/exampleordprddb01/blobServices/default/providers/Microsoft.Insights/diagnosticSettings/external-blob"
      workspace_id      = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      log_categories    = ["StorageRead", "StorageWrite", "StorageDelete"]
      metric_categories = ["Transaction"]
    }
  }
}
backup = null
