# Opt-in baseline detections (var.baseline_content.enabled). Keys carry a
# "compeer-" prefix so they never collide with rules owned by the
# terraform-azurerm-compeer-sentinel module (its Palo Alto CEF rules are
# unprefixed) or with caller rules.
#
# The KQL is the same content as the platform-management example rules. It has
# not been executed against a tenant by this pattern's tests: validate field
# names against the connected tables in a non-production workspace before the
# SOC relies on it. Each rule declares the feeds it reads, so enabling a rule
# whose feed is not provided fails the plan.
locals {
  baseline_scheduled_rules = {
    compeer-new-global-administrator = {
      display_name         = "New Global Administrator assigned"
      description          = "A user was added to the Global Administrator role."
      severity             = "High"
      query_frequency      = "PT15M"
      query_period         = "PT15M"
      tactics              = ["PrivilegeEscalation", "Persistence"]
      techniques           = []
      trigger_operator     = "GreaterThan"
      trigger_threshold    = 0
      enabled              = true
      suppression_duration = null
      custom_details       = {}
      event_grouping       = "SingleAlert"
      query                = <<-KQL
        AuditLogs
        | where OperationName == "Add member to role"
        | mv-expand TargetResources
        | where tostring(TargetResources.displayName) == "Global Administrator"
        | extend InitiatedByUser = tostring(InitiatedBy.user.userPrincipalName)
      KQL
      entity_mappings = [
        { entity_type = "Account", field_mappings = [{ identifier = "FullName", column_name = "InitiatedByUser" }] },
      ]
      alert_details_override = null
      incident               = { create = true, grouping = { enabled = true, lookback_duration = "PT5M", reopen_closed_incidents = false, entity_matching_method = "AnyAlert", by_entities = [], by_alert_details = [], by_custom_details = [] } }
      requires_sources       = ["entra_audit_logs"]
    }
    compeer-owner-role-assigned = {
      display_name         = "Owner role assigned at an Azure scope"
      description          = "The built-in Owner role was assigned at a subscription, management group, resource group or resource."
      severity             = "High"
      query_frequency      = "PT15M"
      query_period         = "PT15M"
      tactics              = ["PrivilegeEscalation"]
      techniques           = []
      trigger_operator     = "GreaterThan"
      trigger_threshold    = 0
      enabled              = true
      suppression_duration = null
      custom_details       = {}
      event_grouping       = "SingleAlert"
      query                = <<-KQL
        AzureActivity
        | where OperationNameValue =~ "MICROSOFT.AUTHORIZATION/ROLEASSIGNMENTS/WRITE"
        | where ActivityStatusValue == "Success"
        | extend RoleDefinitionId = tostring(parse_json(tostring(Properties)).roleDefinitionId)
        | where RoleDefinitionId has "8e3af657-a8ff-443c-a75c-2fe8c4bcb635" // built-in Owner
      KQL
      entity_mappings = [
        { entity_type = "Account", field_mappings = [{ identifier = "FullName", column_name = "Caller" }] },
      ]
      alert_details_override = null
      incident               = { create = true, grouping = { enabled = true, lookback_duration = "PT5M", reopen_closed_incidents = false, entity_matching_method = "AnyAlert", by_entities = [], by_alert_details = [], by_custom_details = [] } }
      requires_sources       = ["azure_activity"]
    }
    compeer-pim-role-activation = {
      display_name           = "PIM eligible role activated"
      description            = "A Privileged Identity Management eligible role was activated. Volume signal: correlate rather than page on every activation."
      severity               = "Medium"
      query_frequency        = "PT15M"
      query_period           = "PT15M"
      tactics                = ["PrivilegeEscalation"]
      techniques             = []
      trigger_operator       = "GreaterThan"
      trigger_threshold      = 0
      enabled                = true
      suppression_duration   = null
      custom_details         = {}
      event_grouping         = "SingleAlert"
      query                  = <<-KQL
        AuditLogs
        | where OperationName has "Add member to role completed (PIM activation)"
      KQL
      entity_mappings        = []
      alert_details_override = null
      incident               = { create = false, grouping = { enabled = true, lookback_duration = "PT5M", reopen_closed_incidents = false, entity_matching_method = "AnyAlert", by_entities = [], by_alert_details = [], by_custom_details = [] } }
      requires_sources       = ["entra_audit_logs"]
    }
    compeer-management-group-or-policy-change = {
      display_name         = "Management group or policy assignment changed"
      description          = "A management group, policy assignment or policy definition was changed."
      severity             = "Medium"
      query_frequency      = "PT15M"
      query_period         = "PT15M"
      tactics              = ["Impact", "DefenseEvasion"]
      techniques           = []
      trigger_operator     = "GreaterThan"
      trigger_threshold    = 0
      enabled              = true
      suppression_duration = null
      custom_details       = {}
      event_grouping       = "SingleAlert"
      query                = <<-KQL
        AzureActivity
        | where ResourceProviderValue in~ ("MICROSOFT.MANAGEMENT", "MICROSOFT.AUTHORIZATION")
        | where OperationNameValue has_any ("managementGroups", "policyAssignments", "policyDefinitions")
        | where ActivityStatusValue == "Success"
      KQL
      entity_mappings = [
        { entity_type = "Account", field_mappings = [{ identifier = "FullName", column_name = "Caller" }] },
      ]
      alert_details_override = null
      incident               = { create = true, grouping = { enabled = true, lookback_duration = "PT5M", reopen_closed_incidents = false, entity_matching_method = "AnyAlert", by_entities = [], by_alert_details = [], by_custom_details = [] } }
      requires_sources       = ["azure_activity"]
    }
    compeer-password-spray-suspected = {
      display_name         = "Possible password spray against multiple accounts"
      description          = "One IP failed sign-in against many accounts in a short window."
      severity             = "Medium"
      query_frequency      = "PT10M"
      query_period         = "PT10M"
      tactics              = ["CredentialAccess"]
      techniques           = []
      trigger_operator     = "GreaterThan"
      trigger_threshold    = 0
      enabled              = true
      suppression_duration = null
      custom_details       = {}
      event_grouping       = "SingleAlert"
      query                = <<-KQL
        SigninLogs
        | where ResultType !in ("0")
        | summarize FailedAccounts = dcount(UserPrincipalName), Attempts = count() by IPAddress, bin(TimeGenerated, 10m)
        | where FailedAccounts >= 5 and Attempts >= 10
      KQL
      entity_mappings = [
        { entity_type = "IP", field_mappings = [{ identifier = "Address", column_name = "IPAddress" }] },
      ]
      alert_details_override = null
      incident               = { create = true, grouping = { enabled = true, lookback_duration = "PT5M", reopen_closed_incidents = false, entity_matching_method = "AnyAlert", by_entities = [], by_alert_details = [], by_custom_details = [] } }
      requires_sources       = ["entra_signin_logs"]
    }
  }

  baseline_scheduled_enabled = var.baseline_content.enabled ? {
    for key, rule in local.baseline_scheduled_rules : key => rule
    if !contains(var.baseline_content.exclude, key)
  } : {}
}
