mock_provider "azurerm" {}
variables {
  apim_name             = "apim-platform"
  resource_group_name   = "rg-apim"
  apim_backend_name     = "orders-backend"
  apim_backend_protocol = "http"
  apim_backend_url      = "https://orders.internal.example.com"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_api_management_backend.apim_backend.name == "orders-backend"
    error_message = "backend name not wired"
  }
  assert {
    condition     = azurerm_api_management_backend.apim_backend.url == "https://orders.internal.example.com"
    error_message = "backend url not wired"
  }
}
