mock_provider "azurerm" {}

variables {
  name                = "stplatform001"
  resource_group_name = "rg-storage"
  location            = "eastus2"
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition     = output.id == azurerm_storage_account.account.id && output.name == azurerm_storage_account.account.name
    error_message = "id/name outputs must echo the resource"
  }
  assert {
    condition     = output.primary_blob_endpoint == azurerm_storage_account.account.primary_blob_endpoint
    error_message = "primary_blob_endpoint output must echo the resource attribute"
  }
  assert {
    condition = (
      output.primary_endpoints.blob == azurerm_storage_account.account.primary_blob_endpoint &&
      output.primary_endpoints.dfs == azurerm_storage_account.account.primary_dfs_endpoint &&
      output.primary_hosts.blob == azurerm_storage_account.account.primary_blob_host
    )
    error_message = "primary_endpoints/primary_hosts maps must echo the correct underlying attribute per key - a copy/paste key mismatch here would go undetected without this"
  }
  assert {
    condition     = output.identity_principal_id == null && output.identity_tenant_id == null
    error_message = "identity outputs must be null when no identity is configured"
  }
}

run "identity_outputs_wired_when_configured" {
  command = apply
  variables {
    identity = { type = "SystemAssigned" }
  }

  assert {
    condition     = output.identity_principal_id == azurerm_storage_account.account.identity[0].principal_id
    error_message = "identity_principal_id output must echo the resource's identity block"
  }
  assert {
    condition     = output.identity_tenant_id == azurerm_storage_account.account.identity[0].tenant_id
    error_message = "identity_tenant_id output must echo the resource's identity block"
  }
}

run "rejects_bad_name" {
  command = plan
  variables {
    name = "ST-Platform-001" # uppercase and hyphens not allowed
  }
  expect_failures = [var.name]
}

run "rejects_bad_account_tier" {
  command = plan
  variables {
    account_tier = "Basic"
  }
  expect_failures = [var.account_tier]
}

run "rejects_bad_account_replication_type" {
  command = plan
  variables {
    account_replication_type = "XRS"
  }
  expect_failures = [var.account_replication_type]
}

run "rejects_bad_account_kind" {
  command = plan
  variables {
    account_kind = "GeneralPurpose"
  }
  expect_failures = [var.account_kind]
}

run "rejects_bad_access_tier" {
  command = plan
  variables {
    access_tier = "Cold"
  }
  expect_failures = [var.access_tier]
}

run "rejects_bad_min_tls_version" {
  command = plan
  variables {
    min_tls_version = "TLS1_3"
  }
  expect_failures = [var.min_tls_version]
}

run "rejects_bad_allowed_copy_scope" {
  command = plan
  variables {
    allowed_copy_scope = "Anywhere"
  }
  expect_failures = [var.allowed_copy_scope]
}

run "rejects_bad_dns_endpoint_type" {
  command = plan
  variables {
    dns_endpoint_type = "Custom"
  }
  expect_failures = [var.dns_endpoint_type]
}

run "rejects_bad_queue_encryption_key_type" {
  command = plan
  variables {
    queue_encryption_key_type = "Custom"
  }
  expect_failures = [var.queue_encryption_key_type]
}

run "rejects_bad_table_encryption_key_type" {
  command = plan
  variables {
    table_encryption_key_type = "Custom"
  }
  expect_failures = [var.table_encryption_key_type]
}

run "rejects_bad_identity_type" {
  command = plan
  variables {
    identity = { type = "Legacy" }
  }
  expect_failures = [var.identity]
}

run "rejects_bad_immutability_policy_state" {
  command = plan
  variables {
    immutability_policy = {
      period_since_creation_in_days = 30
      state                         = "Enabled" # not a real state
    }
  }
  expect_failures = [var.immutability_policy]
}

run "rejects_bad_routing_choice" {
  command = plan
  variables {
    routing = { choice = "DirectRouting" }
  }
  expect_failures = [var.routing]
}

run "rejects_blob_delete_retention_days_out_of_range" {
  command = plan
  variables {
    blob_properties = { delete_retention_days = 400 } # max is 365
  }
  expect_failures = [var.blob_properties]
}

run "rejects_blob_container_delete_retention_days_out_of_range" {
  command = plan
  variables {
    blob_properties = { container_delete_retention_days = 0 } # min is 1
  }
  expect_failures = [var.blob_properties]
}

run "rejects_customer_managed_key_with_neither_key_set" {
  command = plan
  variables {
    customer_managed_key = { user_assigned_identity_id = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id" }
  }
  expect_failures = [var.customer_managed_key]
}

run "rejects_customer_managed_key_with_both_keys_set" {
  command = plan
  variables {
    customer_managed_key = {
      key_vault_key_id          = "https://kv.vault.azure.net/keys/mykey/version"
      managed_hsm_key_id        = "https://hsm.managedhsm.azure.net/keys/mykey/version"
      user_assigned_identity_id = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id"
    }
  }
  expect_failures = [var.customer_managed_key]
}

run "rejects_customer_managed_key_without_user_assigned_identity" {
  # The variable's own validation only checks "exactly one of the two key
  # fields" - a SEPARATE resource-level lifecycle.precondition in main.tf
  # additionally requires user_assigned_identity_id always be set, and had
  # no test proving it actually fires.
  command = plan
  variables {
    customer_managed_key = {
      key_vault_key_id = "https://kv.vault.azure.net/keys/mykey/version"
    }
  }
  expect_failures = [azurerm_storage_account.account]
}

run "accepts_valid_customer_managed_key" {
  command = plan
  variables {
    identity = { type = "UserAssigned", identity_ids = ["/subscriptions/x/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id"] }
    customer_managed_key = {
      key_vault_key_id          = "https://kv.vault.azure.net/keys/mykey/version"
      user_assigned_identity_id = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id"
    }
  }
  assert {
    condition     = azurerm_storage_account.account.customer_managed_key[0].key_vault_key_id == "https://kv.vault.azure.net/keys/mykey/version"
    error_message = "a fully valid customer_managed_key configuration should be accepted"
  }
}

run "rejects_sftp_without_hierarchical_namespace" {
  command = plan
  variables {
    sftp_enabled   = true
    is_hns_enabled = false
  }
  expect_failures = [azurerm_storage_account.account]
}

run "accepts_sftp_with_hierarchical_namespace" {
  command = plan
  variables {
    sftp_enabled   = true
    is_hns_enabled = true
  }
  assert {
    condition     = azurerm_storage_account.account.sftp_enabled == true
    error_message = "sftp_enabled with is_hns_enabled = true should be accepted"
  }
}

run "rejects_nfsv3_without_hierarchical_namespace" {
  command = plan
  variables {
    nfsv3_enabled  = true
    is_hns_enabled = false
  }
  expect_failures = [azurerm_storage_account.account]
}
