locals {
  name_prefix = "${var.application.code}-${var.environment}"

  common_app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = module.application_insights.connection_string
    KEY_VAULT_URI                         = module.key_vault.vault_uri
    STORAGE_ACCOUNT_NAME                  = module.storage_account.name
    AzureWebJobsStorage__accountName      = module.storage_account.name
  }

  diagnostic_targets = {
    key_vault    = module.key_vault.id
    storage      = module.storage_account.id
    function_app = module.function_app.id
    app_insights = module.application_insights.id
  }
}
