mock_provider "azurerm" {}

variables {
  name                = "rsv-backup"
  resource_group_name = "rg-backup"
  location            = "eastus2"
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_recovery_services_vault.this.name == "rsv-backup"
    error_message = "name not wired"
  }
}
