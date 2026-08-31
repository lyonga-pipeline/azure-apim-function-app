mock_provider "azurerm" {}
variables {
  name                = "id-platform-workload"
  resource_group_name = "rg-identity"
  location            = "eastus2"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_user_assigned_identity.this.name == "id-platform-workload"
    error_message = "name not wired"
  }
}
