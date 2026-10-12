mock_provider "azurerm" {}

# Storage roots support metrics only. Service children inherit allLogs,
# while explicit categories must retain the approved resource profile.

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

run "root_defaults_to_metrics_only" {
  command = plan

  variables {
    platform_storage_diagnostics = {
      audit_diag = {
        storage_account_key = "audit"
      }
    }
  }

  assert {
    condition     = length(local.platform_storage_diagnostic_inputs["audit_diag"].logs) == 0
    error_message = "root accounts must not inherit unsupported allLogs"
  }
  assert {
    condition     = keys(local.platform_storage_diagnostic_inputs["audit_diag"].metrics) == tolist(["AllMetrics"])
    error_message = "an entry that leaves metrics unset should default to AllMetrics"
  }
}

run "explicit_diagnostics_are_not_overridden" {
  command = plan

  variables {
    platform_storage_diagnostics = {
      audit_diag = {
        storage_account_key = "audit"
        storage_service     = "blob"
        logs = {
          StorageWrite = { category = "StorageWrite" }
        }
        metrics = {
          Transaction = { category = "Transaction" }
        }
      }
    }
  }

  assert {
    condition     = keys(local.platform_storage_diagnostic_inputs["audit_diag"].logs) == tolist(["StorageWrite"])
    error_message = "an entry with explicit logs should keep exactly what it asked for, not the platform default"
  }
  assert {
    condition     = keys(local.platform_storage_diagnostic_inputs["audit_diag"].metrics) == tolist(["Transaction"])
    error_message = "an entry with explicit metrics should keep exactly what it asked for, not the platform default"
  }
}

run "service_child_defaults_to_all_logs" {
  command = plan
  variables {
    platform_storage_diagnostics = {
      audit_blob = { storage_account_key = "audit", storage_service = "blob" }
    }
  }
  assert {
    condition     = local.platform_storage_diagnostic_inputs.audit_blob.logs.allLogs.category_group == "allLogs" && local.platform_storage_diagnostic_inputs.audit_blob.name == "diag-stauditprodcus001-blob-law"
    error_message = "service child diagnostics must default to allLogs and have a distinct name"
  }
}

run "rejects_logs_on_storage_root" {
  command = plan
  variables {
    platform_storage_diagnostics = {
      audit = { storage_account_key = "audit", logs = { all = { category_group = "allLogs" } } }
    }
  }
  expect_failures = [var.platform_storage_diagnostics]
}
