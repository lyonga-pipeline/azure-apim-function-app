locals {
  diagnostic_ownership              = try(var.policy.diagnostic_ownership, {})
  diagnostic_terraform_mg_keys      = try(local.diagnostic_ownership.terraform_management_group_keys, [])
  diagnostic_terraform_resource_ids = distinct(try(local.diagnostic_ownership.terraform_resource_ids, []))
  diagnostic_shared_scope_enabled   = try(local.diagnostic_ownership.shared_scope_enabled, false)
  diagnostic_profile_dine_enabled   = try(local.diagnostic_ownership.profile_dine_enabled, false) && try(var.policy.remediation.enabled, false)
  diagnostic_profile_dine_effect    = coalesce(try(local.diagnostic_ownership.profile_dine_effect, null), "DeployIfNotExists")
  diagnostic_unresolved_mg_keys = [for key in local.diagnostic_terraform_mg_keys : key
    if try(trimspace(local.management_group_ids[key]), "") == ""
  ]
  diagnostic_terraform_scopes = distinct(concat(
    [for key in local.diagnostic_terraform_mg_keys : contains(local.diagnostic_unresolved_mg_keys, key) ? "unset" : try(
    startswith(local.management_group_ids[key], "/providers/") ? local.management_group_ids[key] : "/providers/Microsoft.Management/managementGroups/${local.management_group_ids[key]}", "unset")],
    try(local.diagnostic_ownership.additional_terraform_scopes, []),
    local.diagnostic_terraform_resource_ids
  ))
  owned_dine_assignments = {
    for key, assignment in try(var.policy.remediation.dine_assignments, {}) : key => merge(
      assignment,
      contains(["app_service_diagnostics", "function_app_diagnostics", "diagnostics_to_log_analytics"], key) ? {
        not_scopes = distinct(concat(try(assignment.not_scopes, []), local.diagnostic_terraform_scopes))
      } : {},
      key == "diagnostics_to_log_analytics" && local.diagnostic_profile_dine_enabled ? {
        parameters = merge(try(assignment.parameters, {}), {
          resourceTypeList = { value = [for resource_type in try(assignment.parameters.resourceTypeList.value, []) : resource_type
            if !contains(local.diagnostic_profile_resource_types_lower, lower(resource_type))
          ] }
        })
      } : {}
    )
  }

  # Audit actual category-based settings without deploying or modifying them.
  diagnostic_audit_profiles               = try(local.diagnostic_ownership.audit_profiles, {})
  diagnostic_profile_resource_types_lower = [for profile in values(local.diagnostic_audit_profiles) : lower(profile.resource_type)]
  # Both effects use the same baseline. Compliance never depends on a setting's name.
  diagnostic_existence_conditions = {
    for key, profile in local.diagnostic_audit_profiles : key => {
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
  diagnostic_audit_definitions = {
    for key, profile in local.diagnostic_audit_profiles : "diagnostic_audit_${key}" => {
      name                 = "compeer-diagnostic-audit-${key}"
      display_name         = "Compeer audit Terraform-owned ${key} diagnostics"
      management_group_key = coalesce(try(local.diagnostic_ownership.definition_management_group_key, null), "compeer-enterprise-mg")
      mode                 = "All"
      description          = "Audit-only: resource owner must correct missing logs in Terraform. No policy deployment, identity, or remediation."
      metadata             = { category = "Monitoring", version = "1.1.0" }
      parameters = {
        logAnalytics     = { type = "String", metadata = { displayName = "Central Log Analytics workspace" } }
        ownedResourceIds = { type = "Array", defaultValue = [], metadata = { displayName = "Explicit Terraform-owned diagnostic targets; empty audits the whole assigned scope" } }
      }
      policy_rule = {
        if = {
          allOf = [
            { field = "type", equals = profile.resource_type },
            { anyOf = [
              { value = "[length(parameters('ownedResourceIds'))]", equals = 0 },
              { field = "id", in = "[parameters('ownedResourceIds')]" }
            ] }
          ]
        }
        then = {
          effect = "AuditIfNotExists"
          details = {
            type               = "Microsoft.Insights/diagnosticSettings"
            existenceCondition = local.diagnostic_existence_conditions[key]
          }
        }
      }
    }
  }
  diagnostic_audit_assignments = merge({
    for key, profile in local.diagnostic_audit_profiles : "diagnostic_audit_registered_${key}" => {
      name                  = "cmp-aud-reg-${substr(sha1(key), 0, 12)}"
      management_group_key  = coalesce(try(local.diagnostic_ownership.definition_management_group_key, null), "compeer-enterprise-mg")
      policy_definition_key = "diagnostic_audit_${key}"
      parameters = {
        logAnalytics     = { value = local.log_analytics_workspace_id }
        ownedResourceIds = { value = local.diagnostic_terraform_resource_ids }
      }
    } if length(local.diagnostic_terraform_resource_ids) > 0
    }, merge([
      for mg_key in local.diagnostic_terraform_mg_keys : {
        for key, profile in local.diagnostic_audit_profiles : "diagnostic_audit_${mg_key}_${key}" => {
          name                  = "cmp-aud-${substr(sha1("${mg_key}:${key}"), 0, 12)}"
          management_group_key  = mg_key
          policy_definition_key = "diagnostic_audit_${key}"
          parameters            = { logAnalytics = { value = local.log_analytics_workspace_id } }
        }
      }
  ]...))

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

  diagnostic_profile_dine_assignments = {
    for key, profile in local.diagnostic_audit_profiles : "diagnostic_profile_${key}" => {
      policy_definition_key = "diagnostic_dine_${key}"
      management_group_key  = coalesce(try(var.policy.remediation.dine_assignments.diagnostics_to_log_analytics.management_group_key, null), try(var.policy.remediation.management_group_key, null), "compeer-enterprise-mg")
      display_name          = "Compeer deploy missing ${key} diagnostic baseline"
      inject_law            = true
      not_scopes            = distinct(concat(local.diagnostic_terraform_scopes, try(var.policy.remediation.dine_assignments.diagnostics_to_log_analytics.not_scopes, [])))
      role_definition_ids   = ["/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293"]
      parameters = {
        effect                = { value = local.diagnostic_profile_dine_effect }
        diagnosticSettingName = { value = "setByPolicy-LogAnalytics" }
      }
    } if local.diagnostic_profile_dine_enabled
  }
}
