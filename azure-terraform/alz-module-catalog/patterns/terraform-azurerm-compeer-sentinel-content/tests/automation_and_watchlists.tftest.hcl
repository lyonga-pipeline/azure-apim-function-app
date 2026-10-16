mock_provider "azurerm" {
  # Watchlist items parse their parent watchlist ID, so a random mock string
  # would be rejected.
  mock_resource "azurerm_sentinel_watchlist" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform/providers/Microsoft.SecurityInsights/watchlists/breakglass-accounts"
    }
  }
}

variables {
  log_analytics_workspace_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-platform"
  tenant_id                   = "11111111-1111-1111-1111-111111111111"
  externally_provided_sources = ["azure_activity"]
  scheduled_rules = {
    owner-assigned = {
      display_name     = "Owner assigned"
      severity         = "High"
      query            = "AzureActivity | take 1"
      requires_sources = ["azure_activity"]
    }
  }
}

run "automation_rule_is_scoped_to_a_rule_owned_here" {
  command = apply
  variables {
    automation_rules = {
      triage-owner-assigned = {
        display_name       = "Triage: Owner assigned"
        order              = 10
        analytic_rule_keys = ["owner-assigned"]
        conditions         = [{ property = "IncidentSeverity", operator = "Equals", values = ["High"] }]
        modify_incident    = [{ order = 1, status = "Active", labels = ["identity"] }]
        incident_tasks     = [{ order = 2, title = "Confirm change ticket" }]
      }
    }
  }

  assert {
    condition = (
      length(jsondecode(azurerm_sentinel_automation_rule.automation["triage-owner-assigned"].condition_json)) == 2 &&
      jsondecode(azurerm_sentinel_automation_rule.automation["triage-owner-assigned"].condition_json)[1].conditionProperties.propertyName == "IncidentRelatedAnalyticRuleIds" &&
      jsondecode(azurerm_sentinel_automation_rule.automation["triage-owner-assigned"].condition_json)[0].conditionType == "Property"
    )
    error_message = "conditions must be encoded in the Sentinel schema and analytic_rule_keys must add the related-rule condition"
  }
  assert {
    condition     = can(regex("(?i)^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", azurerm_sentinel_automation_rule.automation["triage-owner-assigned"].name))
    error_message = "the automation rule name must be a UUID"
  }
}

run "automation_rule_name_is_stable_per_key" {
  command = plan
  variables {
    automation_rules = {
      a = { display_name = "A", order = 1, modify_incident = [{ order = 1, status = "Active" }] }
      b = { display_name = "B", order = 2, modify_incident = [{ order = 1, status = "Active" }] }
    }
  }

  assert {
    condition     = azurerm_sentinel_automation_rule.automation["a"].name != azurerm_sentinel_automation_rule.automation["b"].name
    error_message = "different keys must derive different UUIDs"
  }
}

run "playbook_action_is_accepted" {
  command = plan
  variables {
    automation_rules = {
      notify = {
        display_name = "Notify ServiceNow"
        order        = 5
        playbooks    = [{ order = 1, logic_app_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-soc/providers/Microsoft.Logic/workflows/pb-servicenow" }]
      }
    }
  }

  assert {
    condition     = length(azurerm_sentinel_automation_rule.automation["notify"].action_playbook) == 1
    error_message = "a playbook action must be wired"
  }
}

run "rejects_automation_rule_for_an_unknown_analytic_rule" {
  command = plan
  variables {
    automation_rules = {
      bad = { display_name = "Bad", order = 1, analytic_rule_keys = ["nope"], modify_incident = [{ order = 1, status = "Active" }] }
    }
  }
  expect_failures = [azurerm_sentinel_automation_rule.automation]
}

run "rejects_automation_rule_without_an_action" {
  command = plan
  variables {
    automation_rules = { bad = { display_name = "Bad", order = 1 } }
  }
  expect_failures = [var.automation_rules]
}

run "rejects_duplicate_order" {
  command = plan
  variables {
    automation_rules = {
      a = { display_name = "A", order = 1, modify_incident = [{ order = 1, status = "Active" }] }
      b = { display_name = "B", order = 1, modify_incident = [{ order = 1, status = "Active" }] }
    }
  }
  expect_failures = [var.automation_rules]
}

run "rejects_order_out_of_range" {
  command = plan
  variables {
    automation_rules = { bad = { display_name = "Bad", order = 1001, modify_incident = [{ order = 1, status = "Active" }] } }
  }
  expect_failures = [var.automation_rules]
}

run "rejects_duplicate_action_order" {
  command = plan
  variables {
    automation_rules = {
      bad = {
        display_name    = "Bad"
        order           = 1
        modify_incident = [{ order = 1, status = "Active" }]
        incident_tasks  = [{ order = 1, title = "t" }]
      }
    }
  }
  expect_failures = [var.automation_rules]
}

run "rejects_unknown_condition_property" {
  command = plan
  variables {
    automation_rules = {
      bad = {
        display_name    = "Bad"
        order           = 1
        conditions      = [{ property = "IncidentColor", operator = "Equals", values = ["red"] }]
        modify_incident = [{ order = 1, status = "Active" }]
      }
    }
  }
  expect_failures = [var.automation_rules]
}

run "rejects_unknown_condition_operator" {
  command = plan
  variables {
    automation_rules = {
      bad = {
        display_name    = "Bad"
        order           = 1
        conditions      = [{ property = "IncidentSeverity", operator = "Like", values = ["High"] }]
        modify_incident = [{ order = 1, status = "Active" }]
      }
    }
  }
  expect_failures = [var.automation_rules]
}

run "rejects_closed_without_classification" {
  command = plan
  variables {
    automation_rules = { bad = { display_name = "Bad", order = 1, modify_incident = [{ order = 1, status = "Closed" }] } }
  }
  expect_failures = [var.automation_rules]
}

run "rejects_modify_incident_that_changes_nothing" {
  command = plan
  variables {
    automation_rules = { bad = { display_name = "Bad", order = 1, modify_incident = [{ order = 1 }] } }
  }
  expect_failures = [var.automation_rules]
}

run "rejects_malformed_playbook_id" {
  command = plan
  variables {
    automation_rules = { bad = { display_name = "Bad", order = 1, playbooks = [{ order = 1, logic_app_id = "pb-servicenow" }] } }
  }
  expect_failures = [var.automation_rules]
}

run "watchlist_with_items_is_created" {
  command = apply
  variables {
    watchlists = {
      breakglass-accounts = {
        display_name    = "Break-glass accounts"
        item_search_key = "UserPrincipalName"
        labels          = ["identity"]
        items = {
          bg1 = { UserPrincipalName = "bg1@example.com", Owner = "platform" }
          bg2 = { UserPrincipalName = "bg2@example.com", Owner = "platform" }
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_sentinel_watchlist_item.item) == 2 && contains(keys(output.watchlist_ids), "breakglass-accounts")
    error_message = "a watchlist and its rows must be created"
  }
}

run "rejects_watchlist_row_missing_the_search_key" {
  command = plan
  variables {
    watchlists = {
      bad = { display_name = "Bad", item_search_key = "UserPrincipalName", items = { r1 = { Owner = "platform" } } }
    }
  }
  expect_failures = [var.watchlists]
}

run "rejects_unstable_watchlist_alias" {
  command = plan
  variables {
    watchlists = { "Bad Alias" = { display_name = "Bad", item_search_key = "k" } }
  }
  expect_failures = [var.watchlists]
}
