mock_provider "azurerm" {}
variables {
  name                = "hsm-platform"
  resource_group_name = "rg-hsm"
  location            = "eastus2"
  admin_object_ids    = ["11111111-1111-1111-1111-111111111111"]
  sku_name            = "Standard_B1"
  tenant_id           = "22222222-2222-2222-2222-222222222222"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_key_vault_managed_hardware_security_module.managed_hsm.name == "hsm-platform"
    error_message = "hsm name not wired"
  }
}
