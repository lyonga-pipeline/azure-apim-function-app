mock_provider "azurerm" {}
variables {
  name                = "plan-web"
  resource_group_name = "rg-app"
  location            = "eastus2"
  os_type             = "Linux"
  sku_name            = "P1v3"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_service_plan.service_plan.os_type == "Linux"
    error_message = "os_type not wired"
  }
}
