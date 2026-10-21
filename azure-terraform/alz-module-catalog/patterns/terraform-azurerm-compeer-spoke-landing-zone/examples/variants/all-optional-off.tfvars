# Approved secretless workload: no vault, Blob account, Insights, alerts or VM enrollment.
# Network, UAMI, inspection, tags and authorization remain mandatory foundation controls.
environment = "prod"
key_vault   = { enabled = false }
diagnostics = { enabled = false, existing_settings = {} } # No vault/storage targets exist.
monitoring  = { enabled = false, alerts_enabled = false, create_application_insights = false, create_failed_requests_alert = false }
operations  = { create_action_group = false, platform_action_group_keys = [], action_group_ids = [], notification_emails = [] }
# Keeping a disabled entry is supported: no account, PE, DNS-link request, diagnostics or data role.
storage_accounts = { future_data = { enabled = false, grant_workload_blob_access = false } }
backup           = { enabled = false, recovery_vault_id = "ON_HOLD", backup_policy_id = "ON_HOLD", virtual_machines = {} }
