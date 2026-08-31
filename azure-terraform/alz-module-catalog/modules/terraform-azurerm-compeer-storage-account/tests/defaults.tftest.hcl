mock_provider "azurerm" {}
variables {
  name                = "stplatform001"
  resource_group_name = "rg-storage"
  location            = "eastus2"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_storage_account.this.name == "stplatform001"
    error_message = "name not wired"
  }
}
run "no_op_replan" {
  command = plan
}
