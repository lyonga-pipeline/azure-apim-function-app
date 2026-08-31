mock_provider "azurerm" {}
variables {
  resource_group_name     = "rg-automation"
  automation_account_name = "aa-platform"
  location                = "eastus2"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_automation_account.this.name == "aa-platform"
    error_message = "name not wired"
  }
}
