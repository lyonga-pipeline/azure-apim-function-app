mock_provider "azurerm" {}

variables {
  apim_name           = "apim-platform"
  resource_group_name = "rg-apim"
}

run "none_by_default" {
  command = plan
  assert {
    condition     = length(azurerm_api_management_identity_provider_aad.apim_identity_provider_aad) == 0 && length(azurerm_api_management_identity_provider_aadb2c.apim_identity_provider_aadb2c) == 0
    error_message = "no identity providers managed by default"
  }
}

run "aad_only" {
  command = apply
  variables {
    aad = {
      client_id       = "11111111-1111-1111-1111-111111111111"
      client_secret   = "secret-value"
      allowed_tenants = ["22222222-2222-2222-2222-222222222222"]
    }
  }
  assert {
    condition     = length(azurerm_api_management_identity_provider_aad.apim_identity_provider_aad) == 1
    error_message = "AAD provider should be managed when var.aad is set"
  }
  assert {
    condition     = length(azurerm_api_management_identity_provider_aadb2c.apim_identity_provider_aadb2c) == 0
    error_message = "AADB2C should stay unmanaged"
  }
}
