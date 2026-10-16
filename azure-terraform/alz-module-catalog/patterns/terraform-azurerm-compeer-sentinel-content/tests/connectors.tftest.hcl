mock_provider "azurerm" {}

variables {
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform"
  tenant_id                  = "11111111-1111-1111-1111-111111111111"
}

run "enabled_connectors_are_created_and_named_like_the_legacy_module" {
  command = apply
  variables {
    data_connectors = {
      entra_id              = true
      defender_for_endpoint = true
      threat_intelligence   = { lookback_date = "2026-01-01T00:00:00Z" }
      defender_for_cloud = {
        default = { name = "mdc" }
        second  = { subscription_id = "22222222-2222-2222-2222-222222222222" }
      }
    }
  }

  assert {
    condition = (
      azurerm_sentinel_data_connector_azure_active_directory.entra_id[0].name == "aad" &&
      azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection.defender_for_endpoint[0].name == "mdatp" &&
      azurerm_sentinel_data_connector_threat_intelligence.threat_intelligence[0].name == "ti" &&
      azurerm_sentinel_data_connector_azure_security_center.defender_for_cloud["default"].name == "mdc" &&
      azurerm_sentinel_data_connector_azure_security_center.defender_for_cloud["second"].name == "second"
    )
    error_message = "connector names must match the existing sentinel module (aad, mdatp, ti, mdc) so adopted connectors can be imported"
  }
  assert {
    condition     = length(output.connector_ids) == 5
    error_message = "every enabled connector must be published in connector_ids"
  }
}

run "connectors_provide_telemetry_sources" {
  command = plan
  variables {
    data_connectors = {
      entra_id            = true
      threat_intelligence = {}
      office_365          = {}
    }
  }

  assert {
    condition = (
      contains(output.source_coverage.available, "security_alert") &&
      contains(output.source_coverage.available, "threat_intelligence_indicator") &&
      contains(output.source_coverage.available, "office_activity")
    )
    error_message = "enabled connectors must make their telemetry sources available to rules"
  }
}

run "office_365_with_every_workload_off_is_rejected" {
  command = plan
  variables {
    data_connectors = {
      office_365 = { exchange_enabled = false, sharepoint_enabled = false, teams_enabled = false }
    }
  }
  expect_failures = [var.data_connectors]
}

run "rejects_bad_lookback_date" {
  command = plan
  variables {
    data_connectors = {
      threat_intelligence = { lookback_date = "yesterday" }
    }
  }
  expect_failures = [var.data_connectors]
}

run "rejects_http_taxii_root" {
  command = plan
  variables {
    data_connectors = {
      threat_intelligence_taxii = {
        feed = { display_name = "Feed", api_root_url = "http://feed.example.com/taxii", collection_id = "abc" }
      }
    }
  }
  expect_failures = [var.data_connectors]
}

run "rejects_bad_taxii_polling_frequency" {
  command = plan
  variables {
    data_connectors = {
      threat_intelligence_taxii = {
        feed = { display_name = "Feed", api_root_url = "https://feed.example.com/taxii", collection_id = "abc", polling_frequency = "Hourly" }
      }
    }
  }
  expect_failures = [var.data_connectors]
}

run "rejects_bad_defender_for_cloud_subscription" {
  command = plan
  variables {
    data_connectors = {
      defender_for_cloud = { default = { subscription_id = "sub-1" } }
    }
  }
  expect_failures = [var.data_connectors]
}

run "taxii_password_is_taken_from_the_sensitive_map" {
  command = apply
  variables {
    data_connectors = {
      threat_intelligence_taxii = {
        feed = { display_name = "Feed", api_root_url = "https://feed.example.com/taxii", collection_id = "abc", user_name = "svc" }
      }
    }
    taxii_passwords = { feed = "not-a-real-secret" }
  }

  assert {
    condition     = azurerm_sentinel_data_connector_threat_intelligence_taxii.taxii["feed"].user_name == "svc"
    error_message = "the TAXII connector must be created with its user name"
  }
}
