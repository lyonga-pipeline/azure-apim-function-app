mock_provider "azurerm" {}
variables {
  apim_name            = "apim-platform"
  resource_group_name  = "rg-apim"
  openid_provider_name = "entra"
  client_id            = "11111111-1111-1111-1111-111111111111"
  client_secret        = "test-openid-secret"
  display_name         = "Entra ID"
  metadata_endpoint    = "https://login.microsoftonline.com/tenant/v2.0/.well-known/openid-configuration"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_api_management_openid_connect_provider.apim_openid_connect_provider.name == "entra"
    error_message = "openid provider name not wired"
  }
}
