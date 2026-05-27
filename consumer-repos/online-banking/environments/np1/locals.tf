locals {
  name_prefix = "${var.application.code}-${var.environment}"

  common_app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = module.application_insights.connection_string
    KEY_VAULT_URI                         = module.key_vault.vault_uri
    STORAGE_ACCOUNT_NAME                  = module.storage_account.name
    AzureWebJobsStorage__accountName      = module.storage_account.name
  }

  private_endpoints = {
    key_vault = {
      name              = "${local.name_prefix}-kv-pe"
      target_id         = module.key_vault.id
      subresource_names = ["vault"]
      dns_zone_ids      = [var.shared.private_dns_zone_ids.key_vault]
    }
    storage_blob = {
      name              = "${local.name_prefix}-st-blob-pe"
      target_id         = module.storage_account.id
      subresource_names = ["blob"]
      dns_zone_ids      = [var.shared.private_dns_zone_ids.storage_blob]
    }
    storage_queue = {
      name              = "${local.name_prefix}-st-queue-pe"
      target_id         = module.storage_account.id
      subresource_names = ["queue"]
      dns_zone_ids      = [var.shared.private_dns_zone_ids.storage_queue]
    }
    function_app = {
      name              = "${local.name_prefix}-func-pe"
      target_id         = module.function_app.id
      subresource_names = ["sites"]
      dns_zone_ids      = [var.shared.private_dns_zone_ids.app_service]
    }
  }

  diagnostic_targets = {
    key_vault    = module.key_vault.id
    storage      = module.storage_account.id
    function_app = module.function_app.id
    app_insights = module.application_insights.id
  }
}
