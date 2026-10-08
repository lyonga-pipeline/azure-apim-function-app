resource "terraform_data" "enterprise_policy_contract" {
  count = local.enabled ? 1 : 0

  input = {
    defender_for_cloud_policy_enabled = try(local.defender_policy.enabled, false)
    network_flow_logging_enabled      = try(local.network_flow_logging_policy.enabled, false)
    flow_log_storage_account_id       = local.flow_log_storage_account_id
    log_analytics_workspace_id        = local.log_analytics_workspace_id
    log_analytics_workspace_guid      = local.log_analytics_workspace_guid
    log_analytics_workspace_location  = local.log_analytics_workspace_location
  }

  lifecycle {
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
