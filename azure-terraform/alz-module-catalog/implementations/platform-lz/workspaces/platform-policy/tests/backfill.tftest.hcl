mock_provider "azurerm" {}
mock_provider "tfe" {}

variables {
  tenant_id                 = "00000000-0000-0000-0000-000000000000"
  execution_subscription_id = "00000000-0000-0000-0000-000000000000"
  existing_resource_remediation = {
    defender_targets = {
      network = { subscription_id = "22222222-2222-2222-2222-222222222222", plan_keys = ["defender_servers", "defender_key_vault"] }
    }
    flow_log_targets = {
      network = { subscription_id = "22222222-2222-2222-2222-222222222222", resource_count = 1 }
    }
  }
}

override_data {
  target = data.tfe_outputs.governance[0]
  values = {
    nonsensitive_values = { management_group_ids = { compeer-enterprise-mg = "compeer-enterprise-mg", platform-mg = "platform-mg", workloads-mg = "workloads-mg" } }
  }
}
override_data {
  target = data.tfe_outputs.management[0]
  values = {
    nonsensitive_values = {
      subscription_id                  = "11111111-1111-1111-1111-111111111111"
      log_analytics_workspace_id       = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/law"
      log_analytics_workspace_location = "centralus"
      platform_storage_account_ids     = { audit = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/storage/providers/Microsoft.Storage/storageAccounts/auditcusprod" }
    }
  }
}

run "default_example_is_a_noop" {
  command = plan
  variables { existing_resource_remediation = {} }
  assert {
    condition     = length(local.existing_resource_tasks) == 0 && length(local.remediation.tasks) == 0 && length(terraform_data.existing_resource_remediation_contract) == 0
    error_message = "Adding the example file must not opt existing subscriptions into paid plans or remediation."
  }
}

run "selected_plans_and_flow_log_are_bounded_separate_jobs" {
  command = plan
  assert {
    condition = (
      length(local.remediation.tasks) == 3 && length(module.policy[0].remediation_task_ids) == 3 &&
      local.remediation.tasks["existing-pilot-network-servers"].assignment_key == "defender_servers" &&
      local.remediation.tasks["existing-pilot-network-key_vault"].resource_count == 1 &&
      local.remediation.tasks["existing-pilot-network-servers"].location_filters == null &&
      local.remediation.tasks["existing-pilot-network-vnet-flow"].location_filters == ["centralus"] &&
      local.remediation.tasks["existing-pilot-network-vnet-flow"].resource_count == 1 &&
      alltrue([for task in values(local.remediation.tasks) : task.subscription_id == "/subscriptions/22222222-2222-2222-2222-222222222222" && task.resource_discovery_mode == "ReEvaluateCompliance" && task.parallel_deployments == 1 && task.failure_percentage == 0])
    )
    error_message = "The example must produce only the selected inherited-policy backfills, with correct subscription scope, fresh evaluation and serial bounds."
  }
  assert {
    condition = (
      length(local.defender_for_cloud_dine_assignments) == 8 &&
      contains(local.defender_policy_not_scopes, "/subscriptions/11111111-1111-1111-1111-111111111111") &&
      local.remediation.dine_assignments.defender_servers.parameters.subPlan.value == "P1" &&
      alltrue([for task in values(local.remediation.tasks) : startswith(task.assignment_key, "defender_") || task.assignment_key == "vnet_flow_logs_traffic_analytics"])
    )
    error_message = "Backfill must not add plans, change pricing selections, remove management exclusion, or remediate tags/CIS/direct diagnostics."
  }
}

run "rejects_unapproved_control_key" {
  command = plan
  variables {
    existing_resource_remediation = { defender_targets = { network = { subscription_id = "22222222-2222-2222-2222-222222222222", plan_keys = ["tag_inheritance"] } } }
  }
  expect_failures = [var.existing_resource_remediation]
}

run "rejects_placeholder_subscription" {
  command = plan
  variables {
    existing_resource_remediation = { defender_targets = { network = { subscription_id = "REPLACE_SUBSCRIPTION_UUID", plan_keys = ["defender_key_vault"] } } }
  }
  expect_failures = [var.existing_resource_remediation]
}

run "rejects_duplicate_subscription_targets" {
  command = plan
  variables {
    existing_resource_remediation = {
      defender_targets = {
        first  = { subscription_id = "22222222-2222-2222-2222-222222222222", plan_keys = ["defender_key_vault"] }
        second = { subscription_id = "22222222-2222-2222-2222-222222222222", plan_keys = ["defender_key_vault"] }
      }
    }
  }
  expect_failures = [var.existing_resource_remediation]
}

run "rejects_unbounded_flow_log_request" {
  command = plan
  variables {
    existing_resource_remediation = { flow_log_targets = { network = { subscription_id = "22222222-2222-2222-2222-222222222222", resource_count = 101 } } }
  }
  expect_failures = [var.existing_resource_remediation]
}

run "rejects_targets_when_policy_is_disabled" {
  command = plan
  variables { policy = { enabled = false } }
  expect_failures = [terraform_data.existing_resource_remediation_contract]
}

run "existing_manual_tasks_are_preserved" {
  command = plan
  variables {
    policy = {
      enabled                   = true
      defender_for_cloud_policy = { enabled = true, plans = { key_vault = { enabled = true } } }
      remediation = {
        tasks = { manual-pilot = { assignment_key = "defender_key_vault", subscription_id = "/subscriptions/33333333-3333-3333-3333-333333333333", resource_count = 1 } }
      }
    }
    existing_resource_remediation = {
      defender_targets = { network = { subscription_id = "22222222-2222-2222-2222-222222222222", plan_keys = ["defender_key_vault"] } }
    }
  }
  assert {
    condition = (
      length(local.remediation.tasks) == 2 &&
      local.remediation.tasks["manual-pilot"].subscription_id == "/subscriptions/33333333-3333-3333-3333-333333333333" &&
      local.remediation.tasks["existing-pilot-network-key_vault"].subscription_id == "/subscriptions/22222222-2222-2222-2222-222222222222"
    )
    error_message = "Generated tasks must merge with approved manual tasks rather than replace them."
  }
}

run "rejects_manual_task_name_collision" {
  command = plan
  variables {
    policy = {
      enabled                   = true
      defender_for_cloud_policy = { enabled = true, plans = { key_vault = { enabled = true } } }
      remediation = {
        tasks = { existing-pilot-network-key_vault = { assignment_key = "defender_key_vault", subscription_id = "/subscriptions/33333333-3333-3333-3333-333333333333", resource_count = 1 } }
      }
    }
    existing_resource_remediation = {
      defender_targets = { network = { subscription_id = "22222222-2222-2222-2222-222222222222", plan_keys = ["defender_key_vault"] } }
    }
  }
  expect_failures = [terraform_data.existing_resource_remediation_contract]
}
