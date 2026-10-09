mock_provider "azurerm" {}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  management_group_ids = {
    compeer-enterprise-mg = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
  }
}

run "remediation_off_by_default" {
  command = plan

  assert {
    condition     = length(local.rem_assignments) == 0 && length(local.remediation_assignments_input) == 0
    error_message = "remediation should be inert when not enabled"
  }
  assert {
    condition     = length(terraform_data.remediation_contract) == 0
    error_message = "no contract check should exist when there is nothing to remediate"
  }
}

run "remediation_creates_assignment_with_law_injection" {
  command = plan

  variables {
    remediation = {
      enabled                    = true
      management_group_key       = "compeer-enterprise-mg"
      log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
      dine_assignments = {
        diagnostic_settings = {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000"
          inject_law           = true
          not_scopes           = ["/subscriptions/11111111-1111-1111-1111-111111111111"]
        }
      }
    }
  }

  assert {
    condition     = contains(keys(local.management_group_policy_assignments_input), "rem-diagnostic_settings")
    error_message = "remediation entry should fold into management_group_policy_assignments_input under a rem- prefixed key"
  }
  assert {
    condition     = local.management_group_policy_assignments_input["rem-diagnostic_settings"].identity.type == "SystemAssigned"
    error_message = "remediation assignments always need a SystemAssigned identity"
  }
  assert {
    condition     = local.management_group_policy_assignments_input["rem-diagnostic_settings"].parameters.logAnalytics.value == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
    error_message = "inject_law should add the logAnalytics parameter"
  }
  assert {
    condition     = local.management_group_policy_assignments_input["rem-diagnostic_settings"].not_scopes[0] == "/subscriptions/11111111-1111-1111-1111-111111111111"
    error_message = "remediation not_scopes should pass through so fleet-wide policy can exclude directly owned scopes"
  }
  assert {
    condition     = length(terraform_data.remediation_contract) == 1
    error_message = "the contract check should run when there is something to remediate"
  }
}

run "remediation_accepts_heterogeneous_policy_parameters" {
  command = plan

  variables {
    remediation = {
      enabled                    = true
      management_group_key       = "compeer-enterprise-mg"
      log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
      dine_assignments = {
        app_service = {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/11111111-1111-1111-1111-111111111111"
          inject_law           = true
          parameters = {
            effect = { value = "DeployIfNotExists" }
          }
        }
        resource_catalog = {
          policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/22222222-2222-2222-2222-222222222222"
          inject_law               = true
          parameters = {
            effect           = { value = "DeployIfNotExists" }
            resourceTypeList = { value = ["microsoft.network/virtualnetworks", "microsoft.keyvault/vaults"] }
          }
        }
      }
    }
  }

  assert {
    condition     = length(local.remediation_assignments_input) == 2
    error_message = "DINE assignments with different policy parameter shapes must remain independently typed."
  }
}

run "diagnostic_initiative_gets_identity_and_required_role" {
  command = plan

  variables {
    remediation = {
      enabled                    = true
      management_group_key       = "compeer-enterprise-mg"
      log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
      dine_assignments = {
        diagnostics = {
          policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/0884adba-2312-4468-abeb-5422caed1038"
          inject_law               = true
          role_definition_ids = [
            "/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293",
          ]
        }
      }
    }
  }

  assert {
    condition     = local.management_group_policy_assignments_input["rem-diagnostics"].policy_set_definition_id == "/providers/Microsoft.Authorization/policySetDefinitions/0884adba-2312-4468-abeb-5422caed1038"
    error_message = "remediation must support a built-in policy initiative as well as an individual definition"
  }
  assert {
    condition     = length(azurerm_role_assignment.remediation) == 1
    error_message = "the DINE assignment identity must receive its configured remediation role"
  }
}

run "rejects_missing_management_group_key" {
  command = plan

  variables {
    remediation = {
      enabled = true
      dine_assignments = {
        diagnostic_settings = {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000"
        }
      }
    }
  }

  expect_failures = [terraform_data.remediation_contract]
}

run "rejects_inject_law_without_workspace_id" {
  command = plan

  variables {
    remediation = {
      enabled              = true
      management_group_key = "compeer-enterprise-mg"
      dine_assignments = {
        diagnostic_settings = {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000"
          inject_law           = true
        }
      }
    }
  }

  expect_failures = [terraform_data.remediation_contract]
}
