mock_provider "azurerm" {}

run "empty_is_noop" {
  command = plan
  assert {
    condition     = length(azurerm_role_management_policy.this) == 0
    error_message = "no policies by default"
  }
}

run "activation_rules_with_approval" {
  command = plan
  variables {
    policies = {
      platform_admins_owner = {
        role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635"
        scope              = "/providers/Microsoft.Management/managementGroups/platform-mg"
        activation_rules = {
          maximum_duration                   = "PT8H"
          require_approval                   = true
          require_justification              = true
          require_multifactor_authentication = true
          approvers = [
            { object_id = "11111111-1111-1111-1111-111111111111", type = "Group" }
          ]
        }
      }
    }
  }
  assert {
    condition     = length(azurerm_role_management_policy.this) == 1
    error_message = "expected one role management policy"
  }
  assert {
    condition     = azurerm_role_management_policy.this["platform_admins_owner"].activation_rules[0].require_approval == true
    error_message = "require_approval should be set"
  }
}

run "assignment_rules" {
  command = plan
  variables {
    policies = {
      security_admins = {
        role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/fb1c8493-542b-48eb-b624-b4c8fea62acd"
        scope              = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
        active_assignment_rules = {
          expiration_required = true
          expire_after        = "P90D"
        }
        eligible_assignment_rules = {
          expiration_required = true
          expire_after        = "P365D"
        }
      }
    }
  }
  assert {
    condition     = azurerm_role_management_policy.this["security_admins"].eligible_assignment_rules[0].expire_after == "P365D"
    error_message = "eligible_assignment_rules should be set"
  }
}

run "notification_rules_all_sets" {
  command = plan
  variables {
    policies = {
      network_admins = {
        role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7"
        scope              = "/providers/Microsoft.Management/managementGroups/connectivity-mg"
        notification_rules = {
          eligible_activations = {
            admin_notifications = {
              default_recipients    = true
              notification_level    = "All"
              additional_recipients = ["soc@compeer.example"]
            }
          }
          active_assignments = {
            assignee_notifications = { default_recipients = true }
          }
          eligible_assignments = {
            approver_notifications = { default_recipients = false, additional_recipients = ["security-leads@compeer.example"] }
          }
        }
      }
    }
  }
  assert {
    condition     = length(azurerm_role_management_policy.this["network_admins"].notification_rules) == 1
    error_message = "notification_rules block should be present"
  }
}

run "rejects_unknown_notification_rule_set" {
  command = plan
  variables {
    policies = {
      x = {
        role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000000"
        scope              = "/subscriptions/00000000-0000-0000-0000-000000000000"
        notification_rules = {
          bogus_set = {
            admin_notifications = { default_recipients = true }
          }
        }
      }
    }
  }
  expect_failures = [var.policies]
}
