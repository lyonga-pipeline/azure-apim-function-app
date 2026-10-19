mock_provider "azurerm" {}

variables {
  subscription_id      = "00000000-0000-0000-0000-000000000000"
  management_group_ids = { enterprise = "enterprise" }
  remediation = {
    enabled              = true
    management_group_key = "enterprise"
    dine_assignments = {
      defender_key_vault = {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1f725891-01c0-420a-9059-4fa46cb770b7"
        role_definition_ids  = ["/providers/Microsoft.Authorization/roleDefinitions/fb1c8493-542b-48eb-b624-b4c8fea62acd"]
        parameters           = { effect = { value = "DeployIfNotExists" } }
      }
    }
    tasks = {
      kv-pilot = {
        assignment_key          = "defender_key_vault"
        subscription_id         = "/subscriptions/22222222-2222-2222-2222-222222222222"
        resource_discovery_mode = "ReEvaluateCompliance"
        resource_count          = 1
        parallel_deployments    = 1
        failure_percentage      = 0
      }
    }
  }
}

run "subscription_backfill_reuses_inherited_assignment_and_bounds" {
  command = plan
  assert {
    condition = (
      length(azurerm_subscription_policy_remediation.task) == 1 && length(azurerm_management_group_policy_remediation.task) == 0 &&
      azurerm_subscription_policy_remediation.task["kv-pilot"].subscription_id == "/subscriptions/22222222-2222-2222-2222-222222222222" &&
      azurerm_subscription_policy_remediation.task["kv-pilot"].resource_discovery_mode == "ReEvaluateCompliance" &&
      azurerm_subscription_policy_remediation.task["kv-pilot"].resource_count == 1 &&
      azurerm_subscription_policy_remediation.task["kv-pilot"].parallel_deployments == 1 &&
      azurerm_subscription_policy_remediation.task["kv-pilot"].failure_percentage == 0 &&
      azurerm_subscription_policy_remediation.task["kv-pilot"].location_filters == null &&
      length(local.remediation_assignments_input) == 1 &&
      local.remediation_assignments_input["rem-defender_key_vault"].management_group_id == "/providers/Microsoft.Management/managementGroups/enterprise"
    )
    error_message = "Backfill must remain inside one subscription, reuse the existing MG assignment and retain fresh-scan/serial/failure limits without filtering a subscription by location."
  }
  assert {
    condition     = contains(keys(output.remediation_task_ids), "kv-pilot") && length(azurerm_role_assignment.remediation) == 1
    error_message = "The existing task-ID contract must include sub jobs and reuse assignment remediation RBAC."
  }
}

run "subscription_tasks_default_to_existing_noncompliant" {
  command = plan
  variables {
    remediation = {
      enabled = true, management_group_key = "enterprise"
      dine_assignments = {
        vault = {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1f725891-01c0-420a-9059-4fa46cb770b7"
          role_definition_ids  = ["/providers/Microsoft.Authorization/roleDefinitions/fb1c8493-542b-48eb-b624-b4c8fea62acd"]
        }
      }
      tasks = { vault = { assignment_key = "vault", subscription_id = "/subscriptions/22222222-2222-2222-2222-222222222222" } }
    }
  }
  assert {
    condition     = azurerm_subscription_policy_remediation.task["vault"].resource_discovery_mode == "ExistingNonCompliant"
    error_message = "Existing callers must retain the provider's existing-compliance discovery default."
  }
}

run "rejects_explicitly_excluded_subscription" {
  command = plan
  variables {
    remediation = {
      enabled = true, management_group_key = "enterprise"
      dine_assignments = {
        vault = {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1f725891-01c0-420a-9059-4fa46cb770b7"
          role_definition_ids  = ["/providers/Microsoft.Authorization/roleDefinitions/fb1c8493-542b-48eb-b624-b4c8fea62acd"]
          not_scopes           = ["/SUBSCRIPTIONS/22222222-2222-2222-2222-222222222222/"]
        }
      }
      tasks = { vault = { assignment_key = "vault", subscription_id = "/subscriptions/22222222-2222-2222-2222-222222222222" } }
    }
  }
  expect_failures = [azurerm_subscription_policy_remediation.task]
}

run "rejects_audit_only_task" {
  command = plan
  variables {
    remediation = {
      enabled = true, management_group_key = "enterprise"
      dine_assignments = {
        vault = {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1f725891-01c0-420a-9059-4fa46cb770b7"
          role_definition_ids  = ["/providers/Microsoft.Authorization/roleDefinitions/fb1c8493-542b-48eb-b624-b4c8fea62acd"]
          parameters           = { effect = { value = "AuditIfNotExists" } }
        }
      }
      tasks = { vault = { assignment_key = "vault", subscription_id = "/subscriptions/22222222-2222-2222-2222-222222222222" } }
    }
  }
  expect_failures = [azurerm_subscription_policy_remediation.task]
}

run "rejects_non_enforcing_assignment_task" {
  command = plan
  variables {
    remediation = {
      enabled = true, management_group_key = "enterprise"
      dine_assignments = {
        vault = {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1f725891-01c0-420a-9059-4fa46cb770b7"
          role_definition_ids  = ["/providers/Microsoft.Authorization/roleDefinitions/fb1c8493-542b-48eb-b624-b4c8fea62acd"]
          enforce              = false
        }
      }
      tasks = { vault = { assignment_key = "vault", subscription_id = "/subscriptions/22222222-2222-2222-2222-222222222222" } }
    }
  }
  expect_failures = [azurerm_subscription_policy_remediation.task]
}

run "rejects_subscription_initiative_without_child_reference" {
  command = plan
  variables {
    remediation = {
      enabled = true, management_group_key = "enterprise"
      dine_assignments = {
        diagnostics = {
          policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/0884adba-2312-4468-abeb-5422caed1038"
          role_definition_ids      = ["/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293"]
        }
      }
      tasks = { logs = { assignment_key = "diagnostics", subscription_id = "/subscriptions/22222222-2222-2222-2222-222222222222" } }
    }
  }
  expect_failures = [azurerm_subscription_policy_remediation.task]
}

run "rejects_subscription_placeholders" {
  command = plan
  variables {
    remediation = { tasks = { invalid = { assignment_key = "vault", subscription_id = "REPLACE_SUBSCRIPTION_UUID" } } }
  }
  expect_failures = [var.remediation]
}

run "rejects_reevaluation_at_management_group_scope" {
  command = plan
  variables {
    remediation = { tasks = { invalid = { assignment_key = "vault", resource_discovery_mode = "ReEvaluateCompliance" } } }
  }
  expect_failures = [var.remediation]
}

run "rejects_unknown_discovery_mode" {
  command = plan
  variables {
    remediation = { tasks = { invalid = { assignment_key = "vault", subscription_id = "/subscriptions/22222222-2222-2222-2222-222222222222", resource_discovery_mode = "Always" } } }
  }
  expect_failures = [var.remediation]
}
