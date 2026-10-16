mock_provider "azurerm" {}
mock_provider "tfe" {
  # Terraform 1.7.0 crashes ("unknown complex type: dynamic") generating mock
  # values for tfe_outputs' dynamic attributes, so supply them.
  mock_data "tfe_outputs" {
    defaults = {
      values              = {}
      nonsensitive_values = {}
    }
  }
}

variables {
  tenant_id        = "11111111-1111-1111-1111-111111111111"
  subscription_id  = "00000000-0000-0000-0000-000000000000"
  tfe_organization = "example-org"
}

run "ships_disabled_and_creates_nothing" {
  command = plan

  assert {
    condition     = output.content_inventory == null && length(output.analytics_rule_ids) == 0
    error_message = "the committed example is disabled and must plan no Sentinel content"
  }
}

run "enabled_with_explicit_workspace_creates_content" {
  command = apply
  variables {
    use_tfe_outputs            = false
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform"
    sentinel = {
      enabled                     = true
      externally_provided_sources = ["azure_activity", "entra_audit_logs", "entra_signin_logs"]
      baseline_content            = { enabled = true }
      watchlists = {
        breakglass = { display_name = "Break-glass", item_search_key = "UserPrincipalName" }
      }
    }
  }

  assert {
    condition     = length(output.content_inventory.scheduled_rules) == 5 && contains(keys(output.watchlist_ids), "breakglass")
    error_message = "the baseline rules and watchlists must be created through the pattern"
  }
}

run "enabled_without_a_workspace_id_fails_loudly" {
  command = plan
  variables {
    use_tfe_outputs = false
    sentinel        = { enabled = true }
  }
  expect_failures = [terraform_data.platform_contract]
}

run "management_without_onboarding_blocks_content" {
  command = plan
  variables {
    use_tfe_outputs            = true
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform"
    sentinel                   = { enabled = true }
  }
  expect_failures = [terraform_data.platform_contract]
}

run "manage_onboarding_here_skips_the_management_onboarding_check" {
  command = plan
  variables {
    use_tfe_outputs            = true
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform"
    sentinel                   = { enabled = true, manage_onboarding = true }
  }

  assert {
    condition     = output.content_inventory != null
    error_message = "manage_onboarding = true must let the workspace proceed without a management onboarding output"
  }
}

run "ingestion_is_passed_through_to_the_pattern" {
  command = plan
  variables {
    use_tfe_outputs            = false
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform"
    sentinel = {
      enabled = true
      ingestion = {
        resource_group_name = "rg-mgmt"
        location            = "centralus"
        endpoints           = { logs = { public_network_access_enabled = true } }
        custom_tables       = { Cloudflare_CL = { columns = [{ name = "TimeGenerated", type = "dateTime" }] } }
        rules               = { cloudflare = { preset = "custom_ingestion", endpoint_key = "logs", table_key = "Cloudflare_CL" } }
      }
    }
  }

  assert {
    condition     = output.content_inventory.ingestion.rules == tolist(["cloudflare"]) && contains(output.source_coverage.available, "Cloudflare_CL")
    error_message = "the workspace must hand ingestion through to the pattern"
  }
}
