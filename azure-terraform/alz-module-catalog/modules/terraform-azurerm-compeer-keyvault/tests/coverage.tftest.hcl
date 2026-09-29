mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000000"
      client_id       = "00000000-0000-0000-0000-000000000000"
      object_id       = "00000000-0000-0000-0000-000000000000"
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  name                = "kv-coverage-test"
  resource_group_name = "rg-kv-test"
  location            = "eastus2"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition     = output.id == azurerm_key_vault.keyvault.id && output.name == azurerm_key_vault.keyvault.name
    error_message = "id/name outputs must echo the resource"
  }
  assert {
    condition     = output.vault_uri == azurerm_key_vault.keyvault.vault_uri
    error_message = "vault_uri output must echo the resource attribute"
  }
  assert {
    condition     = output.tenant_id == azurerm_key_vault.keyvault.tenant_id
    error_message = "tenant_id output must echo the resource attribute"
  }
  assert {
    condition     = output.rbac_authorization_enabled == azurerm_key_vault.keyvault.rbac_authorization_enabled
    error_message = "rbac_authorization_enabled output must echo the resource attribute"
  }
  assert {
    condition     = output.private_endpoint_subresource_name == "vault"
    error_message = "private_endpoint_subresource_name should be the fixed 'vault' subresource"
  }
}

run "network_acls_null_omits_the_block" {
  # The default is {} (deny-by-default), not null - the null/omitted path
  # (e.g. a caller intentionally leaving the vault with Azure's own default
  # ACLs) had no test at all.
  command = apply
  variables {
    network_acls = null
  }

  assert {
    condition     = length(azurerm_key_vault.keyvault.network_acls) == 0
    error_message = "network_acls = null should omit the dynamic block entirely"
  }
}

run "contacts_dynamic_block_renders" {
  command = apply
  variables {
    contacts = [
      { email = "secops@compeer.com", name = "SecOps" },
      { email = "platform@compeer.com" },
    ]
  }

  assert {
    condition     = length(azurerm_key_vault.keyvault.contact) == 2
    error_message = "both contacts entries should render as contact blocks"
  }
}

run "rejects_bad_name" {
  command = plan
  variables {
    name = "1kv-starts-with-digit"
  }
  expect_failures = [var.name]
}

run "rejects_bad_sku_name" {
  command = plan
  variables {
    sku_name = "basic"
  }
  expect_failures = [var.sku_name]
}

run "rejects_bad_network_acls_bypass" {
  command = plan
  variables {
    network_acls = { bypass = "Everything", default_action = "Deny" }
  }
  expect_failures = [var.network_acls]
}

run "rejects_bad_network_acls_default_action" {
  command = plan
  variables {
    network_acls = { bypass = "AzureServices", default_action = "Block" }
  }
  expect_failures = [var.network_acls]
}
