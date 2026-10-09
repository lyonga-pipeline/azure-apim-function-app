locals {
  enabled = try(var.policy.enabled, false)

  governance_outputs = merge(
    try(data.tfe_outputs.governance[0].nonsensitive_values, {}),
    try(data.tfe_outputs.governance[0].values, {})
  )

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  management_group_ids = merge(
    try(local.governance_outputs.management_group_ids, {}),
    var.management_group_ids
  )

  log_analytics_workspace_id = coalesce(
    try(var.policy.remediation.log_analytics_workspace_id, null),
    try(local.management_outputs.log_analytics_workspace_id, null),
    try(local.management_outputs.primary_log_analytics_workspace_id, null),
    "unset",
  )

  log_analytics_workspace_guid     = try(local.management_outputs.log_analytics_workspace_guid, null)
  log_analytics_workspace_location = try(local.management_outputs.log_analytics_workspace_location, var.location)
  management_diagnostic_profile    = try(local.management_outputs.diagnostic_profile, null)
  management_subscription_id       = try(local.management_outputs.subscription_id, null)
  management_subscription_scope    = local.management_subscription_id == null ? null : "/subscriptions/${local.management_subscription_id}"
  platform_storage_account_ids     = try(local.management_outputs.platform_storage_account_ids, {})

  defender_policy                                          = try(var.policy.defender_for_cloud_policy, {})
  defender_policy_effect                                   = coalesce(try(local.defender_policy.effect, null), "DeployIfNotExists")
  defender_policy_exclude_platform_management_subscription = try(local.defender_policy.exclude_platform_management_subscription, null) == null ? true : local.defender_policy.exclude_platform_management_subscription
  defender_policy_not_scopes = distinct(concat(
    try(local.defender_policy.not_scopes, []),
    local.defender_policy_exclude_platform_management_subscription && local.management_subscription_scope != null ? [local.management_subscription_scope] : []
  ))
  defender_role_owner    = "/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635"
  defender_role_security = "/providers/Microsoft.Authorization/roleDefinitions/fb1c8493-542b-48eb-b624-b4c8fea62acd"

  defender_for_cloud_dine_assignment_templates = {
    defender_servers = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/5f57b753-04b4-4e5e-aa31-c8888984497a"
      display_name         = "Compeer configure Microsoft Defender for Servers"
      description          = "Enables the approved Defender for Servers plan on descendant landing-zone subscriptions."
      role_definition_ids  = [local.defender_role_owner]
      parameters = {
        effect = { value = local.defender_policy_effect }
        subPlan = {
          value = coalesce(try(local.defender_policy.plans.servers.subplan, null), "P1")
        }
      }
    }
    defender_storage = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cfdc5972-75b3-4418-8ae1-7f5c36839390"
      display_name         = "Compeer configure Microsoft Defender for Storage"
      description          = "Enables Defender for Storage with malware scanning and sensitive-data discovery cost controls."
      role_definition_ids  = [local.defender_role_owner]
      parameters = {
        effect = { value = local.defender_policy_effect }
        isOnUploadMalwareScanningEnabled = {
          value = tostring(coalesce(try(local.defender_policy.plans.storage.on_upload_malware_scanning_enabled, null), true))
        }
        capGBPerMonthPerStorageAccount = {
          value = coalesce(try(local.defender_policy.plans.storage.cap_gb_per_month_per_storage_account, null), 1000)
        }
        isSensitiveDataDiscoveryEnabled = {
          value = tostring(coalesce(try(local.defender_policy.plans.storage.sensitive_data_discovery_enabled, null), true))
        }
      }
    }
    defender_key_vault = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1f725891-01c0-420a-9059-4fa46cb770b7"
      display_name         = "Compeer configure Microsoft Defender for Key Vault"
      description          = "Enables Defender for Key Vault on descendant landing-zone subscriptions."
      role_definition_ids  = [local.defender_role_security]
      parameters = {
        effect  = { value = local.defender_policy_effect }
        subPlan = { value = "PerKeyVault" }
      }
    }
    defender_app_services = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b40e7bcd-a1e5-47fe-b9cf-2f534d0bfb7d"
      display_name         = "Compeer configure Microsoft Defender for App Service"
      description          = "Enables Defender for App Service on descendant landing-zone subscriptions."
      role_definition_ids  = [local.defender_role_security]
      parameters = {
        effect = { value = local.defender_policy_effect }
      }
    }
    defender_sql_databases = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b99b73e7-074b-4089-9395-b7236f094491"
      display_name         = "Compeer configure Microsoft Defender for Azure SQL"
      description          = "Enables Defender for Azure SQL databases on descendant landing-zone subscriptions."
      role_definition_ids  = [local.defender_role_security]
      parameters = {
        effect = { value = local.defender_policy_effect }
      }
    }
    defender_sql_servers_on_machines = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/50ea7265-7d8c-429e-9a7d-ca1f410191c3"
      display_name         = "Compeer configure Microsoft Defender for SQL servers on machines"
      description          = "Enables Defender for SQL servers on VMs/Arc, important for on-prem migration workloads."
      role_definition_ids  = [local.defender_role_security]
      parameters = {
        effect = { value = local.defender_policy_effect }
      }
    }
    defender_containers = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/c9ddb292-b203-4738-aead-18e2716e858f"
      display_name         = "Compeer configure Microsoft Defender for Containers"
      description          = "Enables Defender for Containers for AKS/container workloads as cloud migration expands."
      role_definition_ids  = [local.defender_role_security]
      parameters = {
        effect = { value = local.defender_policy_effect }
      }
    }
    defender_resource_manager = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b7021b2b-08fd-4dc0-9de7-3c6ece09faf9"
      display_name         = "Compeer configure Microsoft Defender for Resource Manager"
      description          = "Enables Defender for Resource Manager to detect suspicious control-plane operations."
      role_definition_ids  = [local.defender_role_security]
      parameters = {
        effect  = { value = local.defender_policy_effect }
        subPlan = { value = "PerSubscription" }
      }
    }
  }

  defender_for_cloud_dine_assignments = !try(local.defender_policy.enabled, false) ? {} : {
    for key, assignment in local.defender_for_cloud_dine_assignment_templates : key => merge(
      assignment,
      length(local.defender_policy_not_scopes) > 0 ? { not_scopes = local.defender_policy_not_scopes } : {}
    )
    if coalesce(try(local.defender_policy.plans[trimprefix(key, "defender_")].enabled, null), true)
  }

  network_flow_logging_policy = try(var.policy.network_flow_logging_policy, {})
  flow_log_storage_account_id = try(coalesce(
    try(local.network_flow_logging_policy.storage_account_id, null),
    try(local.platform_storage_account_ids[try(local.network_flow_logging_policy.storage_account_key, "audit")], null)
  ), null)
  network_flow_logging_effect = coalesce(try(local.network_flow_logging_policy.effect, null), "DeployIfNotExists")

  network_flow_logging_dine_assignments = !try(local.network_flow_logging_policy.enabled, false) ? {} : {
    deploy_network_watcher = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a9b99dd8-06c5-4317-8629-9d86a3c6e7d9"
      display_name         = "Compeer deploy Network Watcher for VNet flow logs"
      description          = "Ensures regional Network Watcher exists before VNet flow-log remediation."
      role_definition_ids = [
        "/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7",
      ]
      parameters = {}
    }
    vnet_flow_logs_traffic_analytics = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/3e9965dc-cc13-47ca-8259-a4252fd0cf7b"
      display_name         = "Compeer deploy VNet flow logs with Traffic Analytics"
      description          = "Deploys VNet flow logs and Traffic Analytics to the central platform Log Analytics workspace for Central US VNets."
      role_definition_ids = [
        "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c",
      ]
      parameters = {
        effect             = { value = local.network_flow_logging_effect }
        vnetRegion         = { value = coalesce(try(local.network_flow_logging_policy.vnet_region, null), var.location) }
        networkWatcherRG   = { value = coalesce(try(local.network_flow_logging_policy.network_watcher_resource_group_name, null), "NetworkWatcherRG") }
        networkWatcherName = { value = coalesce(try(local.network_flow_logging_policy.network_watcher_name, null), "NetworkWatcher_${coalesce(try(local.network_flow_logging_policy.vnet_region, null), var.location)}") }
        storageId          = { value = local.flow_log_storage_account_id }
        retentionDays      = { value = tostring(coalesce(try(local.network_flow_logging_policy.retention_days, null), 90)) }
        timeInterval       = { value = tostring(coalesce(try(local.network_flow_logging_policy.traffic_analytics_interval_minutes, null), 60)) }
        workspaceId        = { value = local.log_analytics_workspace_guid }
        workspaceRegion    = { value = local.log_analytics_workspace_location }
        workspaceResourceId = {
          value = local.log_analytics_workspace_id
        }
      }
    }
  }

  remediation = merge(
    try(var.policy.remediation, {}),
    {
      enabled = (
        try(var.policy.remediation.enabled, false) ||
        try(local.defender_policy.enabled, false) ||
        try(local.network_flow_logging_policy.enabled, false)
      )
      management_group_key = coalesce(
        try(var.policy.remediation.management_group_key, null),
        try(local.defender_policy.management_group_key, null),
        try(local.network_flow_logging_policy.management_group_key, null),
        "compeer-enterprise-mg"
      )
      location = coalesce(
        try(var.policy.remediation.location, null),
        try(local.defender_policy.location, null),
        try(local.network_flow_logging_policy.location, null),
        var.location
      )
    },
    {
      dine_assignments = merge(
        try(var.policy.remediation.dine_assignments, {}),
        local.defender_for_cloud_dine_assignments,
        local.network_flow_logging_dine_assignments,
      )
    },
    local.log_analytics_workspace_id == "unset" ? {} : { log_analytics_workspace_id = local.log_analytics_workspace_id },
  )

  law_remediation_keys = [
    for key, assignment in try(local.remediation.dine_assignments, {}) : key
    if try(assignment.inject_law, false)
  ]
  law_remediation_enabled = try(local.remediation.enabled, false) && length(local.law_remediation_keys) > 0
  diagnostic_remediation_keys = [
    for key in local.law_remediation_keys : key
    if contains(["app_service_diagnostics", "function_app_diagnostics", "diagnostics_to_log_analytics"], key)
  ]
  diagnostic_remediation_enabled        = try(local.remediation.enabled, false) && length(local.diagnostic_remediation_keys) > 0
  diagnostic_dine_resource_types        = try(local.remediation.dine_assignments.diagnostics_to_log_analytics.parameters.resourceTypeList.value, [])
  diagnostic_dine_resource_types_lower  = [for resource_type in local.diagnostic_dine_resource_types : lower(resource_type)]
  diagnostic_dine_setting_name_is_clean = alltrue([for key in local.diagnostic_remediation_keys : try(local.remediation.dine_assignments[key].parameters.diagnosticSettingName.value, null) == "setByPolicy-LogAnalytics"])
}
