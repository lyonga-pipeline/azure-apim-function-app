mock_provider "azurerm" {}

variables {
  name                = "kv-hardening-test"
  resource_group_name = "rg-kv-test"
  location            = "eastus2"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
  tags                = { environment = "test" }
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = azurerm_key_vault.keyvault.public_network_access_enabled == false
    error_message = "public network access must default closed"
  }
  assert {
    condition     = azurerm_key_vault.keyvault.rbac_authorization_enabled == true
    error_message = "RBAC authorization must default on"
  }
  assert {
    condition     = length(azurerm_key_vault.keyvault.access_policy) == 0
    error_message = "no access policies when RBAC is on"
  }
}

run "keyed_access_policies" {
  command = apply

  variables {
    rbac_authorization_enabled = false
    access_policies = {
      group-reader = { tenant_id = "00000000-0000-0000-0000-000000000000", object_id = "11111111-1111-1111-1111-111111111111", secret_permissions = ["Get", "List"] }
    }
  }

  assert {
    condition     = length(azurerm_key_vault.keyvault.access_policy) == 1
    error_message = "keyed access policy should render when RBAC is off"
  }
}

run "rejects_bad_name" {
  command = plan
  variables {
    name = "bad--name"
  }
  expect_failures = [var.name]
}

run "rejects_rbac_off_without_policies" {
  command = plan
  variables {
    rbac_authorization_enabled = false
  }
  expect_failures = [azurerm_key_vault.keyvault]
}
