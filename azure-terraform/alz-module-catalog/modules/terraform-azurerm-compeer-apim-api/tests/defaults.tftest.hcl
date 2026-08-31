mock_provider "azurerm" {}
variables {
  apim_name           = "apim-platform"
  resource_group_name = "rg-apim"
  api_name            = "orders-api"
  revision            = "1"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_api_management_api.api.name == "orders-api"
    error_message = "api name not wired"
  }
  assert {
    condition     = azurerm_api_management_api.api.revision == "1"
    error_message = "revision not wired"
  }
}
