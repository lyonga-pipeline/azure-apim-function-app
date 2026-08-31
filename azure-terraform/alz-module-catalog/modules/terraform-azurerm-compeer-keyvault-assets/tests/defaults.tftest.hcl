mock_provider "azurerm" {}

variables {
  key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
}

run "empty_is_noop" {
  command = plan

  assert {
    condition     = length(azurerm_key_vault_secret.secret) == 0
    error_message = "no secrets by default"
  }
}

run "create_assets" {
  command = plan

  variables {
    secrets = {
      db-password = { value = "s3cr3t" }
    }
    keys = {
      cmk = { key_type = "RSA", key_size = 4096, key_opts = ["wrapKey", "unwrapKey"] }
    }
  }

  assert {
    condition     = azurerm_key_vault_secret.secret["db-password"].name == "db-password"
    error_message = "secret name should default to the map key"
  }
  assert {
    condition     = azurerm_key_vault_key.key["cmk"].key_type == "RSA"
    error_message = "key_type not wired"
  }
}

run "rejects_bad_key_type" {
  command = plan

  variables {
    keys = { bad = { key_type = "AES", key_opts = ["encrypt"] } }
  }

  expect_failures = [var.keys]
}

run "rejects_cert_with_both_import_and_policy" {
  command = plan

  variables {
    certificates = {
      c = {
        import = { contents = "base64==" }
        policy = {
          issuer_parameters = { name = "Self" }
          key_properties    = { exportable = true, key_type = "RSA", reuse_key = false }
          secret_properties = { content_type = "application/x-pkcs12" }
        }
      }
    }
  }

  expect_failures = [azurerm_key_vault_certificate.certificate]
}
