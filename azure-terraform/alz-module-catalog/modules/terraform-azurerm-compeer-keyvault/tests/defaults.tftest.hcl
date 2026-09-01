# Offline tests. `mock_provider` means `apply` runs need no cloud auth.

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
    condition     = azurerm_key_vault.keyvault.purge_protection_enabled == true
    error_message = "purge protection must default on"
  }
  assert {
    condition     = one(azurerm_key_vault.keyvault.network_acls).default_action == "Deny"
    error_message = "network_acls should apply deny-by-default"
  }
  assert {
    condition     = length(azurerm_key_vault.keyvault.access_policy) == 0
    error_message = "no access policies when RBAC is on"
  }
}

run "access_policies_list_and_by_key_merge" {
  command = apply

  variables {
    rbac_authorization_enabled = false
    access_policies = [
      { tenant_id = "00000000-0000-0000-0000-000000000000", object_id = "11111111-1111-1111-1111-111111111111", secret_permissions = ["Get"] },
    ]
    access_policies_by_key = {
      app-deployer = { tenant_id = "00000000-0000-0000-0000-000000000000", object_id = "22222222-2222-2222-2222-222222222222", secret_permissions = ["Get", "List"] }
    }
  }

  assert {
    condition     = length(azurerm_key_vault.keyvault.access_policy) == 2
    error_message = "list + keyed access policies should both render"
  }
}

run "rejects_bad_retention" {
  command = plan

  variables {
    soft_delete_retention_days = 3
  }

  expect_failures = [var.soft_delete_retention_days]
}

run "rejects_rbac_off_without_policies" {
  command = plan

  variables {
    rbac_authorization_enabled = false
  }

  expect_failures = [azurerm_key_vault.keyvault]
}

run "public_requires_firewall_allowlist" {
  command = plan

  variables {
    public_network_access_enabled = true
    network_acls                  = { bypass = "AzureServices", default_action = "Deny" } # no ip_rules / subnets
  }

  expect_failures = [azurerm_key_vault.keyvault]
}

run "public_with_allowlist_ok" {
  command = plan

  variables {
    public_network_access_enabled = true
    network_acls = {
      bypass                     = "AzureServices"
      default_action             = "Deny"
      virtual_network_subnet_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/palo-mgmt"]
    }
  }
}
