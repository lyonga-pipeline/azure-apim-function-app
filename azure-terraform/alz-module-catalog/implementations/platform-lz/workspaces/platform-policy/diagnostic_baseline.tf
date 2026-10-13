locals {
  diagnostic_all_logs_resource_types = distinct(concat(
    [for resource_type in local.diagnostic_dine_resource_types : resource_type
      if !contains(local.diagnostic_profile_resource_types_lower, lower(resource_type))
    ],
    anytrue([for key in keys(local.owned_dine_assignments) : contains(["app_service_diagnostics", "function_app_diagnostics"], key)]) ? ["Microsoft.Web/sites"] : []
  ))
  diagnostic_registered_all_logs_definitions = {
    for key in ["diagnostic_audit_registered_all_logs"] : key => {
      name                 = "compeer-diagnostic-audit-registered-all-logs"
      display_name         = "Compeer audit registered Terraform-owned allLogs diagnostics"
      management_group_key = coalesce(try(local.diagnostic_ownership.definition_management_group_key, null), "compeer-enterprise-mg")
      mode                 = "All"
      description          = "Audit the fleet allLogs baseline only on explicitly registered Terraform-owned targets. Never deploy or modify settings."
      metadata             = { category = "Monitoring", version = "1.0.0" }
      parameters = {
        logAnalytics     = { type = "String" }
        ownedResourceIds = { type = "Array", defaultValue = [] }
      }
      policy_rule = {
        if = { allOf = [
          { field = "id", in = "[parameters('ownedResourceIds')]" },
          { field = "type", in = local.diagnostic_all_logs_resource_types }
        ] }
        then = {
          effect = "AuditIfNotExists"
          details = {
            type = "Microsoft.Insights/diagnosticSettings"
            existenceCondition = { allOf = [
              { field = "Microsoft.Insights/diagnosticSettings/workspaceId", equals = "[parameters('logAnalytics')]" },
              {
                count = {
                  field = "Microsoft.Insights/diagnosticSettings/logs[*]"
                  where = { allOf = [
                    { field = "Microsoft.Insights/diagnosticSettings/logs[*].enabled", equals = true },
                    { field = "Microsoft.Insights/diagnosticSettings/logs[*].categoryGroup", equals = "allLogs" }
                  ] }
                }
                equals = 1
              }
            ] }
          }
        }
      }
    }
    if length(local.diagnostic_terraform_resource_ids) > 0 && length(local.diagnostic_all_logs_resource_types) > 0
  }
  diagnostic_registered_all_logs_assignments = {
    for key, definition in local.diagnostic_registered_all_logs_definitions : key => {
      name                  = "cmp-aud-reg-alllogs"
      management_group_key  = definition.management_group_key
      policy_definition_key = key
      parameters = {
        logAnalytics     = { value = local.log_analytics_workspace_id }
        ownedResourceIds = { value = local.diagnostic_terraform_resource_ids }
      }
    }
  }

  diagnostic_dine_definitions = {
    for key, profile in local.diagnostic_audit_profiles : "diagnostic_dine_${key}" => {
      name                 = "compeer-diagnostic-dine-${key}"
      display_name         = "Compeer deploy ${key} diagnostic baseline"
      management_group_key = coalesce(try(local.diagnostic_ownership.definition_management_group_key, null), "compeer-enterprise-mg")
      mode                 = "All"
      description          = "Recognizes any compliant diagnostic setting; deploys the approved categories only outside explicit Terraform ownership boundaries."
      metadata             = { category = "Monitoring", version = "1.0.0" }
      parameters = {
        effect                = { type = "String", allowedValues = ["DeployIfNotExists", "AuditIfNotExists", "Disabled"], defaultValue = "AuditIfNotExists" }
        logAnalytics          = { type = "String", metadata = { displayName = "Central Log Analytics workspace", strongType = "omsWorkspace", assignPermissions = true } }
        diagnosticSettingName = { type = "String", defaultValue = "setByPolicy-LogAnalytics" }
      }
      policy_rule = {
        if = { field = "type", equals = profile.resource_type }
        then = {
          effect = "[parameters('effect')]"
          details = {
            type               = "Microsoft.Insights/diagnosticSettings"
            evaluationDelay    = "PT30M"
            existenceCondition = local.diagnostic_existence_conditions[key]
            roleDefinitionIds  = ["/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293"]
            deployment = {
              properties = {
                mode = "incremental"
                template = {
                  "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
                  contentVersion = "1.0.0.0"
                  parameters = {
                    resourceId            = { type = "string" }
                    logAnalytics          = { type = "string" }
                    diagnosticSettingName = { type = "string" }
                  }
                  resources = [{
                    type       = "Microsoft.Insights/diagnosticSettings"
                    apiVersion = "2021-05-01-preview"
                    name       = "[parameters('diagnosticSettingName')]"
                    scope      = "[parameters('resourceId')]"
                    properties = {
                      workspaceId = "[parameters('logAnalytics')]"
                      logs        = [for category in profile.log_categories : { category = category, enabled = true }]
                    }
                  }]
                }
                parameters = {
                  resourceId            = { value = "[field('id')]" }
                  logAnalytics          = { value = "[parameters('logAnalytics')]" }
                  diagnosticSettingName = { value = "[parameters('diagnosticSettingName')]" }
                }
              }
            }
          }
        }
      }
    } if local.diagnostic_profile_dine_enabled
  }
}
