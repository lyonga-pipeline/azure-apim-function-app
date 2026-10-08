mock_provider "azurerm" {}

# Platform_Output_Contracts_IAC-10 management_diagnostic_profile: an entry
# that opts into diagnostics but doesn't specify logs/metrics should default
# to allLogs/AllMetrics (modules/terraform-azurerm-compeer-diagnostic-profile),
# not silently end up with an empty, useless diagnostic setting. An entry
# that DOES specify its own logs/metrics must keep exactly what it asked for.

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

run "unspecified_storage_diagnostics_default_to_storage_valid_categories" {
  # A storage account root exposes only metrics (Transaction/Capacity): Azure
  # rejects allLogs ("supported ones are: ''") and AllMetrics there, so the
  # generic diagnostic-profile defaults must not be applied to storage.
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
    error_message = "an account-root entry that leaves logs unset must default to no logs, never allLogs"
  }
  assert {
    condition     = keys(local.platform_storage_diagnostic_inputs["audit_diag"].metrics) == tolist(["Transaction"])
    error_message = "an entry that leaves metrics unset should default to the Transaction metric"
  }
}

run "explicit_diagnostics_are_not_overridden" {
  command = plan

  variables {
    platform_storage_diagnostics = {
      audit_diag = {
        storage_account_key = "audit"
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
