mock_provider "azurerm" {
  # The diagnostic setting validates the workspace ID format; a random mock
  # string would be rejected on apply.
  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform"
    }
  }
  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.Storage/storageAccounts/stauditprodcus001"
    }
  }
}

# Storage diagnostics: the account root supports metrics only; data-plane logs
# (StorageRead/Write/Delete) live on the built-in default child services
# (<account id>/blobServices/default, ...), which exist from the moment the
# account is created - no containers/shares/queues/tables are required.

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  environment     = "prod"
  location        = "centralus"
  resource_group  = { name = "rg-mgmt" }
  log_analytics   = { name = "law-platform" }
  action_group    = { short_name = "mgmt" }
  platform_tags = {
    application         = "platform-management"
    owner               = "platform-team"
    source_repo         = "ado://Compeer/landing-zone"
    created_on          = "2026-01-01"
    criticality_tier    = "tier-1"
    data_classification = "internal"
    lifecycle_state     = "active"
    cost_center         = "CC-0001"
    gl_category         = "cloud"
  }
  platform_storage_accounts = {
    audit = {
      name = "stauditprodcus001"
    }
  }
}

run "blob_service_target_resolves_from_the_account_key" {
  command = apply

  variables {
    platform_storage_diagnostics = {
      audit_blob = {
        storage_account_key = "audit"
        storage_service     = "blob"
      }
    }
  }

  assert {
    condition = (
      local.platform_storage_diagnostic_inputs["audit_blob"].target_resource_id ==
      "${module.platform_storage_accounts["audit"].id}/blobServices/default"
    )
    error_message = "storage_service = blob must target <account id>/blobServices/default"
  }
  assert {
    condition     = endswith(local.platform_storage_diagnostic_inputs["audit_blob"].name, "-blob-law")
    error_message = "the default setting name must include the service so it is distinguishable from the account-level setting"
  }
}

run "service_target_defaults_to_read_write_delete" {
  command = plan

  variables {
    platform_storage_diagnostics = {
      audit_blob = {
        storage_account_key = "audit"
        storage_service     = "blob"
      }
    }
  }

  assert {
    condition = (
      toset([for log in values(local.platform_storage_diagnostic_inputs["audit_blob"].logs) : log.category]) ==
      toset(["StorageRead", "StorageWrite", "StorageDelete"])
    )
    error_message = "a service target must default to StorageRead, StorageWrite and StorageDelete"
  }
}

run "account_and_blob_entries_coexist" {
  command = plan

  variables {
    platform_storage_diagnostics = {
      audit = {
        storage_account_key = "audit"
        logs                = {}
      }
      audit_blob = {
        storage_account_key = "audit"
        storage_service     = "blob"
      }
    }
  }

  assert {
    condition     = length(local.platform_storage_diagnostic_inputs["audit"].logs) == 0 && length(local.platform_storage_diagnostic_inputs["audit_blob"].logs) == 3
    error_message = "the account entry keeps logs = {} while the blob entry carries the three data-plane categories"
  }
  assert {
    condition     = local.platform_storage_diagnostic_inputs["audit"].name != local.platform_storage_diagnostic_inputs["audit_blob"].name
    error_message = "the two default setting names must differ"
  }
}

run "explicit_empty_logs_are_kept_on_a_service_target" {
  command = plan

  variables {
    platform_storage_diagnostics = {
      audit_blob = {
        storage_account_key = "audit"
        storage_service     = "blob"
        logs                = {}
      }
    }
  }

  assert {
    condition     = length(local.platform_storage_diagnostic_inputs["audit_blob"].logs) == 0
    error_message = "an explicit logs = {} must win over the service default"
  }
}

run "explicit_service_logs_are_not_overridden" {
  command = plan

  variables {
    platform_storage_diagnostics = {
      audit_blob = {
        storage_account_key = "audit"
        storage_service     = "blob"
        logs                = { write = { category = "StorageWrite" } }
      }
    }
  }

  assert {
    condition     = keys(local.platform_storage_diagnostic_inputs["audit_blob"].logs) == tolist(["write"])
    error_message = "explicit service logs must be kept exactly as given"
  }
}

run "rejects_unknown_storage_service" {
  command = plan

  variables {
    platform_storage_diagnostics = {
      audit_blob = {
        storage_account_key = "audit"
        storage_service     = "disk"
      }
    }
  }
  expect_failures = [var.platform_storage_diagnostics]
}

run "rejects_storage_service_with_target_resource_id" {
  command = plan

  variables {
    platform_storage_diagnostics = {
      audit_blob = {
        target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/x/blobServices/default"
        storage_service    = "blob"
      }
    }
  }
  expect_failures = [var.platform_storage_diagnostics]
}

run "rejects_blob_service_on_a_file_storage_account" {
  command = plan

  variables {
    platform_storage_accounts = {
      audit = {
        name         = "stauditprodcus001"
        account_kind = "FileStorage"
      }
    }
    platform_storage_diagnostics = {
      audit_blob = {
        storage_account_key = "audit"
        storage_service     = "blob"
      }
    }
  }
  expect_failures = [terraform_data.platform_storage_diagnostics_contract]
}

run "accepts_file_service_on_a_file_storage_account" {
  command = plan

  variables {
    platform_storage_accounts = {
      audit = {
        name         = "stauditprodcus001"
        account_kind = "FileStorage"
      }
    }
    platform_storage_diagnostics = {
      audit_file = {
        storage_account_key = "audit"
        storage_service     = "file"
      }
    }
  }

  assert {
    condition     = length(local.platform_storage_diagnostic_inputs["audit_file"].logs) == 3
    error_message = "a file service on a FileStorage account is valid"
  }
}
