mock_provider "azurerm" {}

variables {
  subscription_id      = "00000000-0000-0000-0000-000000000000"
  management_group_ids = { enterprise = "enterprise", workloads = "workloads" }
  custom_policy_definitions = {
    flow = { management_group_key = "enterprise", display_name = "Flow", policy_rule = { if = { field = "type", equals = "Microsoft.Network/virtualNetworks" }, then = { effect = "Audit" } } }
  }
  remediation = {
    enabled              = true
    management_group_key = "enterprise"
    dine_assignments = {
      flow = {
        management_group_key  = "workloads"
        policy_definition_key = "flow"
        role_definition_ids   = ["/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"]
      }
      diagnostic = {
        policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/0884adba-2312-4468-abeb-5422caed1038"
        role_definition_ids      = ["/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293"]
      }
    }
  }
}

run "assignment_and_rbac_follow_individual_scope" {
  command = plan
  assert {
    condition     = local.remediation_assignments_input["rem-flow"].management_group_id == "/providers/Microsoft.Management/managementGroups/workloads" && azurerm_role_assignment.remediation["flow:b24988ac-6180-42a0-ab88-20f7382dd24c"].scope == "/providers/Microsoft.Management/managementGroups/workloads"
    error_message = "Assignment and RBAC must share the caller's actual target scope."
  }
  assert {
    condition     = local.remediation_assignments_input["rem-flow"].policy_definition_key == "flow" && length(azurerm_management_group_policy_remediation.task) == 0
    error_message = "Custom definitions are supported and tasks stay opt-in."
  }
}

run "approved_tasks_are_bounded" {
  command = plan
  variables {
    remediation = {
      enabled              = true
      management_group_key = "workloads"
      dine_assignments = {
        flow = {
          policy_definition_key = "flow"
          role_definition_ids   = ["/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"]
        }
      }
      tasks = { flow-pilot-01 = { assignment_key = "flow", resource_count = 20, parallel_deployments = 2 } }
    }
  }
  assert {
    condition     = azurerm_management_group_policy_remediation.task["flow-pilot-01"].resource_count == 20 && azurerm_management_group_policy_remediation.task["flow-pilot-01"].parallel_deployments == 2
    error_message = "Approved task limits must be respected."
  }
}

run "initiative_task_requires_reference_id" {
  command = plan
  variables {
    remediation = {
      enabled              = true
      management_group_key = "enterprise"
      dine_assignments = {
        diagnostic = {
          policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/0884adba-2312-4468-abeb-5422caed1038"
          role_definition_ids      = ["/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293"]
        }
      }
      tasks = { diagnostics-pilot-01 = { assignment_key = "diagnostic" } }
    }
  }
  expect_failures = [azurerm_management_group_policy_remediation.task]
}

run "invalid_task_limits_rejected" {
  command = plan
  variables {
    remediation = { tasks = { invalid = { assignment_key = "flow", parallel_deployments = 31 } } }
  }
  expect_failures = [var.remediation]
}
