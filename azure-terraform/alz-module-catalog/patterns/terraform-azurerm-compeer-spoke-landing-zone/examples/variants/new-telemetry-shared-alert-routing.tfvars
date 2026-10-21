# Create an application-specific component/rule; reuse the platform team's approved escalation route.
environment      = "prod"
key_vault        = { enabled = true, sku_name = "standard" }
diagnostics      = { enabled = true, existing_settings = {} }
storage_accounts = {}
monitoring = {
  enabled                      = true
  create_application_insights  = true
  alerts_enabled               = true
  create_failed_requests_alert = true
  sampling_percentage          = 100
  failed_request_threshold     = 5
  internet_ingestion_enabled   = true
  internet_query_enabled       = true
  private_link_ready           = false
}
operations = {
  create_action_group        = false
  platform_action_group_keys = ["primary"]
  action_group_ids           = []
  notification_emails        = []
}
backup = null
