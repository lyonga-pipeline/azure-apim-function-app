mock_provider "azurerm" {}
mock_provider "tfe" {}

variables {
  tenant_id                 = "00000000-0000-0000-0000-000000000000"
  execution_subscription_id = "00000000-0000-0000-0000-000000000000"
}

override_data {
  target = data.tfe_outputs.governance[0]
  values = {
    values = {}
    nonsensitive_values = {
      contract_version = "0.1.0"
      management_group_ids = {
        compeer-enterprise-mg = "compeer-enterprise-mg"
        platform-mg           = "platform-mg"
        workloads-mg          = "workloads-mg"
      }
    }
  }
}

override_data {
  target = data.tfe_outputs.management[0]
  values = {
    values = {}
    nonsensitive_values = {
      contract_version                 = "0.1.0"
      subscription_id                  = "11111111-1111-1111-1111-111111111111"
      log_analytics_workspace_id       = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/law"
      log_analytics_workspace_location = "centralus"
      platform_storage_account_ids = {
        audit = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/storage/providers/Microsoft.Storage/storageAccounts/auditcusprod"
      }
    }
  }
}

run "production_ownership_boundaries" {
  command = plan
  assert {
    condition = alltrue([for key in local.diagnostic_remediation_keys :
      contains(local.remediation.dine_assignments[key].not_scopes, "/providers/Microsoft.Management/managementGroups/platform-mg")
    ])
    error_message = "Every diagnostic DINE assignment must exclude Terraform-owned platform scopes."
  }
  assert {
    condition     = contains(local.defender_policy_not_scopes, "/subscriptions/11111111-1111-1111-1111-111111111111") && length(local.defender_for_cloud_dine_assignments) == 8
    error_message = "Only explicitly approved Defender plans may deploy, outside the direct management subscription."
  }
  assert {
    condition     = length(local.diagnostic_audit_assignments) == 3 && length(local.diagnostic_builtin_audit_assignments) == 3 && length(local.remediation.tasks) == 0
    error_message = "Platform resources need read-only checks, without automatic remediation tasks."
  }
  assert {
    condition     = local.diagnostic_audit_definitions.diagnostic_audit_key_vault.policy_rule.then.effect == "AuditIfNotExists" && local.diagnostic_audit_profiles.key_vault.log_categories == ["AuditEvent"]
    error_message = "Key Vault's actual approved category must be audited, not overwritten to satisfy a default profile."
  }
  assert {
    condition     = !contains(local.diagnostic_dine_resource_types_lower, "microsoft.insights/components") && !contains(local.diagnostic_dine_resource_types_lower, "microsoft.storage/storageaccounts")
    error_message = "Application Insights and storage roots must not inherit allLogs exports."
  }
}

run "flow_log_requires_approved_configuration" {
  command = plan
  assert {
    condition = alltrue([
      local.flow_logging_definitions.compeer_vnet_flow_logging.policy_rule.then.details.existenceCondition.allOf[0].equals == true,
      local.flow_logging_definitions.compeer_vnet_flow_logging.policy_rule.then.details.existenceCondition.allOf[1].equals == "[parameters('storageId')]",
      local.flow_logging_definitions.compeer_vnet_flow_logging.policy_rule.then.details.existenceCondition.allOf[3].equals == "[parameters('workspaceResourceId')]",
      local.flow_logging_definitions.compeer_vnet_flow_logging.policy_rule.then.details.existenceCondition.allOf[7].equals == "[int(parameters('retentionDays'))]"
    ])
    error_message = "Disabled flow logs or logs with the wrong destinations/retention cannot be compliant."
  }
  assert {
    condition     = local.remediation.dine_assignments.vnet_flow_logs_traffic_analytics.policy_definition_key == "compeer_vnet_flow_logging" && strcontains(local.flow_log_name, "first(field(")
    error_message = "The assignment must use the strict definition and reuse an existing flow-log name."
  }
}

run "omitted_defender_plans_stay_disabled" {
  command = plan
  variables {
    policy = {
      enabled                   = true
      defender_for_cloud_policy = { enabled = true, plans = { servers = { enabled = true, subplan = "P1" } } }
    }
  }
  assert {
    condition     = keys(local.defender_for_cloud_dine_assignments) == tolist(["defender_servers"])
    error_message = "Enabling Servers must not silently enable seven other paid plans."
  }
}

run "preserves_independent_feature_scopes" {
  command = plan
  variables {
    policy = {
      enabled                     = true
      defender_for_cloud_policy   = { enabled = true, management_group_key = "workloads-mg", plans = { servers = { enabled = true } } }
      network_flow_logging_policy = { enabled = true, management_group_key = "platform-mg" }
    }
  }
  assert {
    condition     = local.remediation.dine_assignments.defender_servers.management_group_key == "workloads-mg" && local.remediation.dine_assignments.vnet_flow_logs_traffic_analytics.management_group_key == "platform-mg"
    error_message = "Defender and flow-log scopes must not be collapsed to one management group."
  }
}

run "rejects_unknown_defender_plan" {
  command = plan
  variables {
    policy = { enabled = true, defender_for_cloud_policy = { plans = { typo = { enabled = true } } } }
  }
  expect_failures = [terraform_data.enterprise_policy_contract]
}

run "rejects_diagnostic_dine_without_ownership" {
  command = plan
  variables {
    policy = {
      enabled = true
      remediation = {
        enabled = true
        dine_assignments = {
          app_service_diagnostics = {
            policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/c0d8e23a-47be-4032-961f-8b0ff3957061"
            inject_law           = true
            parameters           = { diagnosticSettingName = { value = "setByPolicy-LogAnalytics" } }
          }
        }
      }
    }
  }
  expect_failures = [terraform_data.enterprise_policy_contract]
}

run "storage_extensions_require_explicit_opt_in" {
  command = plan
  variables {
    policy = { enabled = true, defender_for_cloud_policy = { enabled = true, plans = { storage = { enabled = true } } } }
  }
  assert {
    condition     = local.defender_for_cloud_dine_assignments.defender_storage.parameters.isOnUploadMalwareScanningEnabled.value == "false" && local.defender_for_cloud_dine_assignments.defender_storage.parameters.isSensitiveDataDiscoveryEnabled.value == "false"
    error_message = "Storage plan opt-in alone must not silently enable extra scanning features."
  }
}

run "rejects_unreadable_public_management_contract" {
  command = plan
  variables {
    policy = { enabled = true, defender_for_cloud_policy = { enabled = true, plans = { servers = { enabled = true } } } }
  }
  override_data {
    target = data.tfe_outputs.management[0]
    values = { values = { subscription_id = "11111111-1111-1111-1111-111111111111" }, nonsensitive_values = {} }
  }
  expect_failures = [terraform_data.enterprise_policy_contract]
}
