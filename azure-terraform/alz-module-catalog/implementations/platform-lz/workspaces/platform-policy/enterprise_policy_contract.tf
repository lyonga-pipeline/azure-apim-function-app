resource "terraform_data" "enterprise_policy_contract" {
  count = local.enabled ? 1 : 0

  input = {
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
      error_message = "defender_for_cloud_policy.enabled defaults to excluding platform-management's directly managed subscription. Apply platform-management first so it publishes subscription_id, or set defender_for_cloud_policy.exclude_platform_management_subscription = false with explicit ownership approval."
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
        local.management_diagnostic_profile != null
      )
      error_message = "Diagnostic DINE is enabled, but platform-management has not published diagnostic_profile."
    }

    precondition {
      condition = (
        !local.diagnostic_remediation_enabled ||
        try(local.management_diagnostic_profile.destination_key, null) == "log_analytics_workspace_id"
      )
      error_message = "Diagnostic DINE expects platform-management's diagnostic_profile.destination_key to be log_analytics_workspace_id."
    }

    precondition {
      condition = (
        !local.diagnostic_remediation_enabled ||
        try(contains(local.management_diagnostic_profile.log_categories, "allLogs"), false)
      )
      error_message = "Diagnostic DINE expects platform-management's diagnostic_profile.log_categories to include allLogs."
    }

    precondition {
      condition = (
        !local.diagnostic_remediation_enabled ||
        try(contains(local.management_diagnostic_profile.metric_categories, "AllMetrics"), false)
      )
      error_message = "Diagnostic DINE expects platform-management's diagnostic_profile.metric_categories to include AllMetrics."
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
      condition = (
        !try(local.network_flow_logging_policy.enabled, false) ||
        local.log_analytics_workspace_guid != null
      )
      error_message = "network_flow_logging_policy.enabled requires platform-management to publish log_analytics_workspace_guid."
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
