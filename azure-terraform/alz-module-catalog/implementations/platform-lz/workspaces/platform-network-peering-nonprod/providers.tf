provider "azapi" {
  # One provider addresses all approved non-production VNet subscriptions by ARM ID.
  tenant_id                  = var.tenant_id
  subscription_id            = var.execution_subscription_id
  skip_provider_registration = true
  use_cli                    = var.allow_local_cli_auth
  use_oidc                   = var.tfc_azure_dynamic_credentials != null
  client_id_file_path        = try(var.tfc_azure_dynamic_credentials.default.client_id_file_path, null)
  oidc_token_file_path       = try(var.tfc_azure_dynamic_credentials.default.oidc_token_file_path, null)
}
provider "tfe" {}
