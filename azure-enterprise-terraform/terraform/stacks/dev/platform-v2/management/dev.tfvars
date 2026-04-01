environment                      = "dev"
application                      = "management"
created_by                       = "terraform"
location                         = "eastus2"
subscription_id                  = "65ac2b14-e13a-40a0-bb50-93359232816e"
subscription_catalog_entry_key   = "management"
resource_group_name              = "rg-dev-management"
workspace_name                   = "law-dev-management"
diagnostics_storage_account_name = "stdevdiag001"
action_group_name                = "ag-dev-ops"
recovery_services_vault_name     = "rsv-dev-platform"

action_group_email_receivers = {}

business_owner      = "operations"
source_repo         = "azure-apim-function-app"
terraform_workspace = "platform-v2-management-dev"
recovery_tier       = "rubrik"
cost_center         = "shared-ops"
creation_date_utc   = "2026-03-09T00:00:00Z"

subscriptions_state_subscription_id = "65ac2b14-e13a-40a0-bb50-93359232816e"

additional_tags = {
  owner = "charles"
}
