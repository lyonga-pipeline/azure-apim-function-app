locals {
  # Adapted from Microsoft's VNet flow-log policy 3e9965dc (v1.1.1).
  # Microsoft's MIT notice is retained in flow_logging_policy.LICENSE.
  # Keep its existing-log naming to update a Policy-owned log, not duplicate it.
  flow_log_existing_ids = "field('Microsoft.Network/virtualNetworks/flowLogs[*].id')"
  flow_log_empty        = "empty(coalesce(${local.flow_log_existing_ids}))"
  flow_log_rg           = "[if(${local.flow_log_empty}, parameters('networkWatcherRG'), split(first(${local.flow_log_existing_ids}), '/')[4])]"
  flow_log_watcher      = "[if(${local.flow_log_empty}, last(split(parameters('networkWatcherName'), '/')), split(first(${local.flow_log_existing_ids}), '/')[8])]"
  flow_log_name         = "[if(${local.flow_log_empty}, concat(take(concat(field('name'), '-', resourceGroup().name), 72), '-flowlog'), split(first(${local.flow_log_existing_ids}), '/')[10])]"

  flow_logging_definitions = {
    for key, definition in {
      compeer_vnet_flow_logging = {
        name                 = "compeer-vnet-flow-logging"
        display_name         = "Compeer enforce approved VNet flow logging and Traffic Analytics"
        management_group_key = coalesce(try(local.network_flow_logging_policy.definition_management_group_key, null), "compeer-enterprise-mg")
        mode                 = "Indexed"
        description          = "Policy-owned flow logs must be enabled and match approved storage, workspace, interval, retention and format. Exclude Terraform-owned flow-log scopes."
        metadata = {
          category = "Network"
          version  = "1.0.0"
          source   = "https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Network/VirtualNetwork_FlowLog_TrafficAnalytics_DINE.json"
        }
        parameters = merge(
          { for parameter in ["vnetRegion", "storageId", "workspaceResourceId", "workspaceRegion", "networkWatcherRG", "networkWatcherName", "retentionDays"] : parameter => { type = "String" } },
          {
            effect       = { type = "String", allowedValues = ["DeployIfNotExists", "Disabled"], defaultValue = "DeployIfNotExists" }
            timeInterval = { type = "String", allowedValues = ["10", "60"], defaultValue = "60" }
          }
        )
        policy_rule = {
          if = { allOf = [
            { field = "type", equals = "Microsoft.Network/virtualNetworks" },
            { field = "location", equals = "[parameters('vnetRegion')]" }
          ] }
          then = {
            effect = "[parameters('effect')]"
            details = {
              type              = "Microsoft.Network/networkWatchers/flowLogs"
              evaluationDelay   = "AfterProvisioningSuccess"
              resourceGroupName = local.flow_log_rg
              name              = "[if(${local.flow_log_empty}, 'null/null', concat(split(first(${local.flow_log_existing_ids}), '/')[8], '/', split(first(${local.flow_log_existing_ids}), '/')[10]))]"
              existenceCondition = {
                allOf = [
                  { field = "Microsoft.Network/networkWatchers/flowLogs/enabled", equals = true },
                  { field = "Microsoft.Network/networkWatchers/flowLogs/storageId", equals = "[parameters('storageId')]" },
                  { field = "Microsoft.Network/networkWatchers/flowLogs/flowAnalyticsConfiguration.networkWatcherFlowAnalyticsConfiguration.enabled", equals = true },
                  { field = "Microsoft.Network/networkWatchers/flowLogs/flowAnalyticsConfiguration.networkWatcherFlowAnalyticsConfiguration.workspaceResourceId", equals = "[parameters('workspaceResourceId')]" },
                  { field = "Microsoft.Network/networkWatchers/flowLogs/flowAnalyticsConfiguration.networkWatcherFlowAnalyticsConfiguration.workspaceRegion", equals = "[parameters('workspaceRegion')]" },
                  { field = "Microsoft.Network/networkWatchers/flowLogs/flowAnalyticsConfiguration.networkWatcherFlowAnalyticsConfiguration.trafficAnalyticsInterval", equals = "[int(parameters('timeInterval'))]" },
                  { field = "Microsoft.Network/networkWatchers/flowLogs/retentionPolicy.enabled", equals = true },
                  { field = "Microsoft.Network/networkWatchers/flowLogs/retentionPolicy.days", equals = "[int(parameters('retentionDays'))]" },
                  { field = "Microsoft.Network/networkWatchers/flowLogs/format.type", equals = "JSON" },
                  { field = "Microsoft.Network/networkWatchers/flowLogs/format.version", equals = 2 }
                ]
              }
              roleDefinitionIds = ["/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"]
              deployment = {
                properties = {
                  mode = "Incremental"
                  template = {
                    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
                    contentVersion = "1.0.0.0"
                    parameters     = { for parameter in ["storageId", "workspaceResourceId", "workspaceRegion", "networkWatcherRG", "networkWatcherName", "flowlogName", "location", "targetResource", "retentionDays", "timeInterval"] : parameter => { type = "string" } }
                    resources = [{
                      type          = "Microsoft.Resources/deployments"
                      name          = "[concat('flowlogDeployment-', uniqueString(parameters('flowlogName')))]"
                      apiVersion    = "2022-09-01"
                      resourceGroup = "[parameters('networkWatcherRG')]"
                      properties = {
                        mode = "Incremental"
                        template = {
                          "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
                          contentVersion = "1.0.0.0"
                          resources = [{
                            type       = "Microsoft.Network/networkWatchers/flowLogs"
                            name       = "[concat(parameters('networkWatcherName'), '/', parameters('flowlogName'))]"
                            apiVersion = "2022-09-01"
                            location   = "[parameters('location')]"
                            properties = {
                              targetResourceId = "[parameters('targetResource')]"
                              storageId        = "[parameters('storageId')]"
                              enabled          = true
                              format           = { type = "JSON", version = 2 }
                              retentionPolicy  = { enabled = true, days = "[int(parameters('retentionDays'))]" }
                              flowAnalyticsConfiguration = {
                                networkWatcherFlowAnalyticsConfiguration = {
                                  enabled                  = true
                                  workspaceRegion          = "[parameters('workspaceRegion')]"
                                  workspaceResourceId      = "[parameters('workspaceResourceId')]"
                                  trafficAnalyticsInterval = "[int(parameters('timeInterval'))]"
                                }
                              }
                            }
                          }]
                        }
                      }
                    }]
                  }
                  parameters = merge(
                    { for parameter in ["storageId", "workspaceResourceId", "workspaceRegion", "retentionDays", "timeInterval"] : parameter => { value = "[parameters('${parameter}')]" } },
                    {
                      networkWatcherRG   = { value = local.flow_log_rg }
                      networkWatcherName = { value = local.flow_log_watcher }
                      flowlogName        = { value = local.flow_log_name }
                      location           = { value = "[field('location')]" }
                      targetResource     = { value = "[field('id')]" }
                    }
                  )
                }
              }
            }
          }
        }
      }
    } : key => definition if try(local.network_flow_logging_policy.enabled, false)
  }
}
