run "defaults_match_documented_platform_standard" {
  command = plan

  assert {
    condition     = length(output.log_categories) == 1 && output.log_categories[0] == "allLogs"
    error_message = "default log category_group should be allLogs"
  }
  assert {
    condition     = length(output.metric_categories) == 1 && output.metric_categories[0] == "AllMetrics"
    error_message = "default metric category should be AllMetrics"
  }
  assert {
    condition     = output.destination_key == "log_analytics_workspace_id"
    error_message = "default destination_key should point at log_analytics_workspace_id"
  }
  assert {
    condition     = output.profile.log_categories[0] == "allLogs" && output.profile.metric_categories[0] == "AllMetrics" && output.profile.destination_key == "log_analytics_workspace_id"
    error_message = "profile object should combine all three defaults"
  }
}

run "override_is_respected" {
  command = plan

  variables {
    log_category_group = "audit"
    metric_category    = "Transaction"
    destination_key    = "log_analytics_workspace_ids"
  }

  assert {
    condition     = output.profile.log_categories[0] == "audit"
    error_message = "override of log_category_group should flow through"
  }
  assert {
    condition     = output.profile.destination_key == "log_analytics_workspace_ids"
    error_message = "override of destination_key should flow through"
  }
}
