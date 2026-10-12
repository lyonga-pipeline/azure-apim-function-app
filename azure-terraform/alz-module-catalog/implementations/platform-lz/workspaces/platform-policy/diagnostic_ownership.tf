locals {
  diagnostic_ownership         = try(var.policy.diagnostic_ownership, {})
  diagnostic_terraform_mg_keys = try(local.diagnostic_ownership.terraform_management_group_keys, [])
  diagnostic_terraform_scopes = distinct(concat(
    [for key in local.diagnostic_terraform_mg_keys : try(
    startswith(local.management_group_ids[key], "/providers/") ? local.management_group_ids[key] : "/providers/Microsoft.Management/managementGroups/${local.management_group_ids[key]}", "unset")],
    try(local.diagnostic_ownership.additional_terraform_scopes, [])
  ))
  owned_dine_assignments = {
    for key, assignment in try(var.policy.remediation.dine_assignments, {}) : key => merge(
      assignment,
      contains(["app_service_diagnostics", "function_app_diagnostics", "diagnostics_to_log_analytics"], key) ? {
        not_scopes = distinct(concat(try(assignment.not_scopes, []), local.diagnostic_terraform_scopes))
      } : {}
    )
  }

  # Audit actual category-based settings without deploying or modifying them.
  diagnostic_audit_profiles = try(local.diagnostic_ownership.audit_profiles, {})
  diagnostic_audit_definitions = {
    for key, profile in local.diagnostic_audit_profiles : "diagnostic_audit_${key}" => {
      name                 = "compeer-diagnostic-audit-${key}"
      display_name         = "Compeer audit Terraform-owned ${key} diagnostics"
      management_group_key = coalesce(try(local.diagnostic_ownership.definition_management_group_key, null), "compeer-enterprise-mg")
      mode                 = "All"
      description          = "Audit-only: resource owner must correct missing logs in Terraform. No policy deployment, identity, or remediation."
      metadata             = { category = "Monitoring", version = "1.0.0" }
      parameters = {
        logAnalytics = { type = "String", metadata = { displayName = "Central Log Analytics workspace" } }
      }
      policy_rule = {
        if = { field = "type", equals = profile.resource_type }
        then = {
          effect = "AuditIfNotExists"
          details = {
            type = "Microsoft.Insights/diagnosticSettings"
            existenceCondition = {
              allOf = concat(
                [{ field = "Microsoft.Insights/diagnosticSettings/workspaceId", equals = "[parameters('logAnalytics')]" }],
                [for category in profile.log_categories : {
                  count = {
                    field = "Microsoft.Insights/diagnosticSettings/logs[*]"
                    where = {
                      allOf = [
                        { field = "Microsoft.Insights/diagnosticSettings/logs[*].enabled", equals = true },
                        { anyOf = [
                          { field = "Microsoft.Insights/diagnosticSettings/logs[*].category", equals = category },
                          { field = "Microsoft.Insights/diagnosticSettings/logs[*].categoryGroup", equals = "allLogs" }
                        ] }
                      ]
                    }
                  }
                  greater = 0
                }]
              )
            }
          }
        }
      }
    }
  }
  diagnostic_audit_assignments = merge([
    for mg_key in local.diagnostic_terraform_mg_keys : {
      for key, profile in local.diagnostic_audit_profiles : "diagnostic_audit_${mg_key}_${key}" => {
        name                  = "cmp-aud-${substr(sha1("${mg_key}:${key}"), 0, 12)}"
        management_group_key  = mg_key
        policy_definition_key = "diagnostic_audit_${key}"
        parameters            = { logAnalytics = { value = local.log_analytics_workspace_id } }
      }
    }
  ]...)

  diagnostic_builtin_audit_assignments = merge([
    for mg_key in local.diagnostic_terraform_mg_keys : {
      for key, assignment in local.owned_dine_assignments : "diagnostic_audit_${mg_key}_${key}" => {
        name                     = "cmp-aud-${substr(sha1("${mg_key}:${key}"), 0, 12)}"
        management_group_key     = mg_key
        policy_definition_id     = try(assignment.policy_definition_id, null)
        policy_set_definition_id = try(assignment.policy_set_definition_id, null)
        parameters = merge(try(assignment.parameters, {}), {
          effect       = { value = "AuditIfNotExists" }
          logAnalytics = { value = local.log_analytics_workspace_id }
          }, key == "diagnostics_to_log_analytics" ? {
          resourceTypeList = { value = [for resource_type in local.diagnostic_dine_resource_types : resource_type
            if !contains([for profile in values(local.diagnostic_audit_profiles) : lower(profile.resource_type)], lower(resource_type))
          ] }
        } : {})
      } if contains(["app_service_diagnostics", "function_app_diagnostics", "diagnostics_to_log_analytics"], key)
    }
  ]...)
}
