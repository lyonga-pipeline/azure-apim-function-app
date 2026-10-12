resource "terraform_data" "enterprise_policy_contract" {
  count = local.enabled ? 1 : 0

  input = {
    governance_workspace_name                          = var.governance_workspace_name
    governance_public_output_names                     = keys(local.governance_outputs)
    available_management_group_keys                    = keys(local.management_group_ids)
    unresolved_diagnostic_management_group_keys        = local.diagnostic_unresolved_mg_keys
    management_workspace_name                          = var.management_workspace_name
    management_public_output_names                     = keys(local.management_outputs)
    defender_for_cloud_policy_enabled                  = try(local.defender_policy.enabled, false)
    defender_policy_excludes_management_subscription   = local.defender_policy_exclude_platform_management_subscription
    defender_policy_not_scopes                         = local.defender_policy_not_scopes
    diagnostic_remediation_enabled                     = local.diagnostic_remediation_enabled
    diagnostic_remediation_keys                        = local.diagnostic_remediation_keys
    diagnostic_remediation_setting_name_is_policy_only = local.diagnostic_dine_setting_name_is_clean
    flow_log_storage_account_id                        = local.flow_log_storage_account_id
    law_remediation_enabled                            = local.law_remediation_enabled
    log_analytics_workspace_id                         = local.log_analytics_workspace_id
    log_analytics_workspace_guid                       = local.log_analytics_workspace_guid
    log_analytics_workspace_location                   = local.log_analytics_workspace_location
    management_diagnostic_profile                      = local.management_diagnostic_profile
    diagnostic_terraform_scopes                        = local.diagnostic_terraform_scopes
    diagnostic_audit_profile_names                     = keys(local.diagnostic_audit_profiles)
    management_subscription_scope                      = local.management_subscription_scope
    network_flow_logging_enabled                       = try(local.network_flow_logging_policy.enabled, false)
  }

  lifecycle {
    precondition {
      condition = (
        !try(local.defender_policy.enabled, false) ||
        !local.defender_policy_exclude_platform_management_subscription ||
        local.management_subscription_scope != null
      )
      error_message = "Defender DINE cannot exclude the directly managed subscription: workspace ${var.management_workspace_name} has no readable public subscription_id. Verify the workspace name and scoped output access, apply its updated outputs, or set the root Terraform variable management_subscription_id to the actual management subscription UUID. Public output names: ${jsonencode(keys(local.management_outputs))}. Keep the ownership exclusion enabled."
    }

    precondition {
      condition = var.management_subscription_id == null || local.published_management_subscription_id == null ? true : (
        lower(var.management_subscription_id) == lower(local.published_management_subscription_id)
      )
      error_message = "management_subscription_id disagrees with the subscription_id published by ${var.management_workspace_name}. Correct the explicit ID or producer workspace before configuring Defender exclusions."
    }

    precondition {
      condition = (
        !local.law_remediation_enabled ||
        local.log_analytics_workspace_id != "unset"
      )
      error_message = "Log Analytics remediation is enabled, but platform-management has not published log_analytics_workspace_id."
    }

    precondition {
      condition = (
        !local.diagnostic_remediation_enabled ||
        length(local.diagnostic_terraform_mg_keys) > 0 && !contains(local.diagnostic_terraform_scopes, "unset") && length(local.diagnostic_audit_profiles) > 0
      )
      error_message = "Diagnostic DINE requires Terraform-owned management-group keys resolving to non-empty IDs and category-based audit_profiles. Unresolved keys: ${jsonencode(local.diagnostic_unresolved_mg_keys)}. Available keys: ${jsonencode(keys(local.management_group_ids))}. Governance workspace: ${var.governance_workspace_name}; public output names: ${jsonencode(keys(local.governance_outputs))}. Verify its applied management_group_ids output and scoped access, or provide the root management_group_ids map keyed exactly as diagnostic_ownership.terraform_management_group_keys."
    }

    precondition {
      condition = (
        !local.diagnostic_remediation_enabled ||
        local.log_analytics_workspace_id != "unset"
      )
      error_message = "Diagnostic audit and DINE must target the same published central workspace."
    }

    precondition {
      condition = (
        length(local.diagnostic_audit_assignments) == 0 || local.log_analytics_workspace_id != "unset"
      )
      error_message = "Audit-only diagnostic checks require the central workspace ID."
    }

    precondition {
      condition = (
        alltrue([for profile in values(local.diagnostic_audit_profiles) :
          length(profile.log_categories) > 0 && !contains(["microsoft.storage/storageaccounts", "microsoft.insights/components"], lower(profile.resource_type))
        ])
      )
      error_message = "Audit profiles must have explicit log categories and target log-capable resources, not storage roots or Application Insights."
    }

    precondition {
      condition = (
        !local.diagnostic_remediation_enabled ||
        local.diagnostic_dine_setting_name_is_clean
      )
      error_message = "Diagnostic DINE assignments must use diagnosticSettingName = setByPolicy-LogAnalytics so Policy-owned settings do not collide with Terraform-owned diagnostic settings."
    }

    precondition {
      condition = (
        !local.diagnostic_remediation_enabled ||
        !contains(local.diagnostic_dine_resource_types_lower, "microsoft.storage/storageaccounts")
      )
      error_message = "Do not put Microsoft.Storage/storageAccounts in diagnostics_to_log_analytics.resourceTypeList. Storage account root diagnostics do not support allLogs; manage storage child-resource diagnostics explicitly in the owning workspace."
    }

    precondition {
      condition = (
        !try(local.network_flow_logging_policy.enabled, false) ||
        local.log_analytics_workspace_id != "unset"
      )
      error_message = "network_flow_logging_policy.enabled requires platform-management to publish log_analytics_workspace_id."
    }

    precondition {
      condition     = !contains(local.diagnostic_dine_resource_types_lower, "microsoft.insights/components")
      error_message = "Do not export workspace-based Application Insights diagnostics to its underlying central workspace. Remove Microsoft.Insights/components from policy.remediation.dine_assignments.diagnostics_to_log_analytics.parameters.resourceTypeList.value in the effective configuration. Check HCP policy variables, variable sets, and auto.tfvars overrides as well as terraform.tfvars."
    }

    precondition {
      condition = alltrue([for key, plan in try(local.defender_policy.plans, {}) :
        contains([for name in keys(local.defender_for_cloud_dine_assignment_templates) : trimprefix(name, "defender_")], key) &&
        can(tobool(plan.enabled))
      ])
      error_message = "Defender plan keys must be supported and each configured plan must explicitly set enabled. Omitted plans stay disabled."
    }

    precondition {
      condition     = contains(["DeployIfNotExists", "Disabled"], local.defender_policy_effect) && contains(["DeployIfNotExists", "Disabled"], local.network_flow_logging_effect)
      error_message = "Defender and flow-log deployment effects must be DeployIfNotExists or Disabled."
    }

    precondition {
      condition     = contains(["P1", "P2"], coalesce(try(local.defender_policy.plans.servers.subplan, null), "P1"))
      error_message = "Defender for Servers subplan must be P1 or P2."
    }

    precondition {
      condition = (
        !try(local.network_flow_logging_policy.enabled, false) ||
        (contains([10, 60], coalesce(try(local.network_flow_logging_policy.traffic_analytics_interval_minutes, null), 60)) &&
          coalesce(try(local.network_flow_logging_policy.retention_days, null), 90) >= 1 &&
        floor(coalesce(try(local.network_flow_logging_policy.retention_days, null), 90)) == coalesce(try(local.network_flow_logging_policy.retention_days, null), 90))
      )
      error_message = "Flow logging requires interval 10 or 60 minutes and positive integer storage retention_days."
    }

    precondition {
      condition = (
        !try(local.network_flow_logging_policy.enabled, false) ||
        local.flow_log_storage_account_id != null
      )
      error_message = "network_flow_logging_policy.enabled requires a flow-log storage account ID. Set policy.network_flow_logging_policy.storage_account_id or ensure platform-management publishes platform_storage_account_ids.audit."
    }
  }
}
