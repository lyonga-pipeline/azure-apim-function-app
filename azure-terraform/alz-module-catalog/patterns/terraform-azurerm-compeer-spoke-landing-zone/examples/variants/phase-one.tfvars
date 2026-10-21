# Phase 1 default: required network/identity plus a dedicated audited private vault.
environment      = "prod"
key_vault        = { enabled = true, sku_name = "standard", secret_readers = {}, secret_officer_group_ids = {} }
diagnostics      = { enabled = true, existing_settings = {} }
monitoring       = { enabled = false, alerts_enabled = false, create_application_insights = false, create_failed_requests_alert = false }
operations       = { create_action_group = false, platform_action_group_keys = [], action_group_ids = [], notification_emails = [] }
storage_accounts = {}
backup           = null
