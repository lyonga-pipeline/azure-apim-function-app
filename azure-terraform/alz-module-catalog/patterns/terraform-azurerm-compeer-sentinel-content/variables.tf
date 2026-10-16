# Sentinel content-as-code. This pattern owns what the SOC tunes (connectors,
# analytics rules, automation rules, watchlists). It does NOT own the Log
# Analytics workspace, the telemetry export plumbing (Activity Log / Entra
# diagnostic settings / CEF forwarders), Defender plan enablement, or RBAC -
# see README "Ownership".

variable "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace (published by platform-management). Sentinel must already be onboarded on it unless manage_onboarding = true."
  type        = string

  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/resourceGroups/[^/]+/providers/Microsoft\\.OperationalInsights/workspaces/[^/]+$", var.log_analytics_workspace_id))
    error_message = "log_analytics_workspace_id must be a full Log Analytics workspace resource ID."
  }
}

variable "tenant_id" {
  description = "Entra tenant ID for tenant-level connectors. Null uses the provider's current tenant; set it explicitly in enterprise roots so a connector can never bind to the wrong tenant."
  type        = string
  default     = null

  validation {
    condition     = var.tenant_id == null ? true : can(regex("(?i)^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be null or a UUID."
  }
}

variable "manage_onboarding" {
  description = "True: this state also onboards the workspace to Sentinel. Keep false when platform-management already owns the onboarding - one workspace can only be onboarded once, and two states must never own it."
  type        = bool
  default     = false
}

variable "externally_provided_sources" {
  description = "Telemetry feeds that something OUTSIDE this state delivers into the workspace (for example azure_activity via the subscription Activity Log diagnostic setting, entra_audit_logs/entra_signin_logs via the tenant Entra diagnostic setting, common_security_log via the CEF forwarder). Rules that declare requires_sources are only allowed to deploy when every source is provided here or by an enabled connector in this state."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for source in var.externally_provided_sources :
      contains([
        "azure_activity", "entra_audit_logs", "entra_signin_logs", "common_security_log",
        "security_alert", "threat_intelligence_indicator", "office_activity", "syslog",
        "windows_security_events", "azure_diagnostics",
      ], source)
    ])
    error_message = "externally_provided_sources entries must be known sources: azure_activity, entra_audit_logs, entra_signin_logs, common_security_log, security_alert, threat_intelligence_indicator, office_activity, syslog, windows_security_events, azure_diagnostics."
  }
}

variable "enforce_source_dependencies" {
  description = "True (default): fail the plan when an enabled rule's requires_sources are not provided. Sentinel rejects or silently never fires rules whose source table does not exist yet, so this turns an apply-time surprise into a plan-time message."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Data connectors - only the connectors azurerm can own. There is no azurerm
# connector for Azure Activity, Syslog/CEF or Windows Security Events: those
# are delivered by diagnostic settings / data collection rules (see README).
# -----------------------------------------------------------------------------

variable "data_connectors" {
  description = "Terraform-owned Sentinel data connectors. Tenant-level connectors need the run identity to hold the Entra/Defender permissions Microsoft documents for each connector (typically Global or Security Administrator at connect time) and the matching license."
  type = object({
    entra_id                = optional(bool, false) # Entra ID Protection alerts into SecurityAlert; sign-in/audit LOGS need the tenant diagnostic setting
    defender_xdr            = optional(bool, false) # Microsoft Defender XDR incidents and alerts
    defender_for_endpoint   = optional(bool, false)
    defender_for_identity   = optional(bool, false)
    defender_for_cloud_apps = optional(object({ alerts_enabled = optional(bool, true), discovery_logs_enabled = optional(bool, false) }))
    office_atp              = optional(bool, false) # Defender for Office 365
    office_365 = optional(object({
      exchange_enabled   = optional(bool, true)
      sharepoint_enabled = optional(bool, true)
      teams_enabled      = optional(bool, true)
    }))
    defender_for_cloud = optional(map(object({
      subscription_id = optional(string) # null = the provider's subscription
      name            = optional(string) # connector name; default is the map key
    })), {})
    threat_intelligence           = optional(object({ lookback_date = optional(string) }))
    microsoft_threat_intelligence = optional(object({ lookback_date = string }))
    threat_intelligence_taxii = optional(map(object({
      display_name      = string
      api_root_url      = string
      collection_id     = string
      user_name         = optional(string)
      polling_frequency = optional(string)
      lookback_date     = optional(string)
    })), {})
  })
  default = {}

  validation {
    condition     = try(var.data_connectors.office_365, null) == null ? true : (var.data_connectors.office_365.exchange_enabled || var.data_connectors.office_365.sharepoint_enabled || var.data_connectors.office_365.teams_enabled)
    error_message = "office_365 needs at least one of exchange_enabled, sharepoint_enabled or teams_enabled; omit office_365 to leave the connector off."
  }
  validation {
    condition = alltrue([
      for value in compact([
        try(var.data_connectors.threat_intelligence.lookback_date, null),
        try(var.data_connectors.microsoft_threat_intelligence.lookback_date, null),
      ]) : can(formatdate("YYYY", value))
    ])
    error_message = "Threat-intelligence lookback_date values must be RFC3339 timestamps, for example 2026-01-01T00:00:00Z."
  }
  validation {
    condition     = alltrue([for key in keys(var.data_connectors.defender_for_cloud) : can(regex("^[a-z0-9][a-z0-9-]{0,62}$", coalesce(try(var.data_connectors.defender_for_cloud[key].name, null), key)))])
    error_message = "defender_for_cloud connector names (the key, or name when set) must be lowercase letters, numbers and hyphens."
  }
  validation {
    condition     = alltrue([for key in keys(var.data_connectors.defender_for_cloud) : try(var.data_connectors.defender_for_cloud[key].subscription_id, null) == null ? true : can(regex("(?i)^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", var.data_connectors.defender_for_cloud[key].subscription_id))])
    error_message = "defender_for_cloud subscription_id values must be UUIDs."
  }
  validation {
    condition     = alltrue([for item in values(var.data_connectors.threat_intelligence_taxii) : can(regex("^https://", item.api_root_url))])
    error_message = "threat_intelligence_taxii api_root_url must be an https:// URL."
  }
  validation {
    condition     = alltrue([for item in values(var.data_connectors.threat_intelligence_taxii) : item.polling_frequency == null ? true : contains(["OnceAMinute", "OnceAnHour", "OnceADay"], item.polling_frequency)])
    error_message = "threat_intelligence_taxii polling_frequency must be OnceAMinute, OnceAnHour or OnceADay."
  }
  validation {
    condition     = alltrue([for item in values(var.data_connectors.threat_intelligence_taxii) : item.lookback_date == null ? true : can(formatdate("YYYY", item.lookback_date))])
    error_message = "threat_intelligence_taxii lookback_date must be an RFC3339 timestamp such as 2026-01-01T00:00:00Z."
  }
}

variable "taxii_passwords" {
  description = "TAXII feed passwords keyed like data_connectors.threat_intelligence_taxii. Supply from a secret store at run time (HCP sensitive variable); never commit them."
  type        = map(string)
  default     = {}
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Analytics rules
# -----------------------------------------------------------------------------

variable "scheduled_rules" {
  description = "Custom scheduled analytics rules keyed by a stable rule name (the key is the Azure resource name; renaming it replaces the rule). requires_sources declares the telemetry the query reads - see externally_provided_sources."
  type = map(object({
    display_name         = string
    description          = optional(string)
    severity             = string
    query                = string
    query_frequency      = optional(string, "PT1H")
    query_period         = optional(string, "PT1H")
    trigger_operator     = optional(string, "GreaterThan")
    trigger_threshold    = optional(number, 0)
    tactics              = optional(set(string), [])
    techniques           = optional(set(string), [])
    enabled              = optional(bool, true)
    suppression_duration = optional(string) # set to enable suppression for that long
    custom_details       = optional(map(string), {})
    event_grouping       = optional(string, "SingleAlert")
    entity_mappings = optional(list(object({
      entity_type = string
      field_mappings = list(object({
        identifier  = string
        column_name = string
      }))
    })), [])
    alert_details_override = optional(object({
      display_name_format  = optional(string)
      description_format   = optional(string)
      severity_column_name = optional(string)
      tactics_column_name  = optional(string)
    }))
    incident = optional(object({
      create = optional(bool, true)
      grouping = optional(object({
        enabled                 = optional(bool, true)
        lookback_duration       = optional(string, "PT5M")
        reopen_closed_incidents = optional(bool, false)
        entity_matching_method  = optional(string, "AnyAlert")
        by_entities             = optional(list(string), [])
        by_alert_details        = optional(list(string), [])
        by_custom_details       = optional(list(string), [])
      }), {})
    }), {})
    requires_sources = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.scheduled_rules) : can(regex("^[a-z0-9][a-z0-9_-]{0,62}$", key))])
    error_message = "scheduled_rules keys must be lowercase letters, numbers, hyphens or underscores (they become Azure resource names)."
  }
  validation {
    condition     = alltrue([for rule in values(var.scheduled_rules) : contains(["High", "Medium", "Low", "Informational"], rule.severity)])
    error_message = "scheduled_rules[*].severity must be High, Medium, Low or Informational."
  }
  validation {
    condition     = alltrue([for rule in values(var.scheduled_rules) : contains(["Equal", "GreaterThan", "LessThan", "NotEqual"], rule.trigger_operator)])
    error_message = "scheduled_rules[*].trigger_operator must be Equal, GreaterThan, LessThan or NotEqual."
  }
  validation {
    condition = alltrue([
      for rule in values(var.scheduled_rules) :
      can(regex("^P(?:[0-9]+D)?(?:T(?:[0-9]+H)?(?:[0-9]+M)?(?:[0-9]+S)?)?$", rule.query_frequency)) &&
      can(regex("^P(?:[0-9]+D)?(?:T(?:[0-9]+H)?(?:[0-9]+M)?(?:[0-9]+S)?)?$", rule.query_period)) &&
      (rule.suppression_duration == null ? true : can(regex("^P(?:[0-9]+D)?(?:T(?:[0-9]+H)?(?:[0-9]+M)?(?:[0-9]+S)?)?$", rule.suppression_duration)))
    ])
    error_message = "scheduled_rules query_frequency, query_period and suppression_duration must be ISO-8601 durations such as PT15M, PT1H or P1D."
  }
  validation {
    condition = alltrue([
      for rule in values(var.scheduled_rules) :
      alltrue([for tactic in rule.tactics : contains([
        "Collection", "CommandAndControl", "CredentialAccess", "DefenseEvasion", "Discovery", "Execution",
        "Exfiltration", "ImpairProcessControl", "InhibitResponseFunction", "Impact", "InitialAccess",
        "LateralMovement", "Persistence", "PrivilegeEscalation", "PreAttack", "Reconnaissance", "ResourceDevelopment",
      ], tactic)])
    ])
    error_message = "scheduled_rules tactics must be provider-supported values such as InitialAccess, Persistence, PrivilegeEscalation, CredentialAccess, DefenseEvasion, Impact."
  }
  validation {
    condition     = alltrue([for rule in values(var.scheduled_rules) : alltrue([for technique in rule.techniques : can(regex("^T[0-9]{4}$", technique))])])
    error_message = "scheduled_rules techniques must be MITRE technique IDs such as T1078."
  }
  validation {
    condition     = alltrue([for rule in values(var.scheduled_rules) : length(trimspace(rule.query)) > 0 && length(rule.display_name) > 0])
    error_message = "scheduled_rules need a non-empty display_name and query."
  }
  validation {
    condition     = alltrue([for rule in values(var.scheduled_rules) : contains(["AlertPerResult", "SingleAlert"], rule.event_grouping)])
    error_message = "scheduled_rules[*].event_grouping must be AlertPerResult or SingleAlert."
  }
  validation {
    condition     = alltrue([for rule in values(var.scheduled_rules) : contains(["AnyAlert", "Selected", "AllEntities"], rule.incident.grouping.entity_matching_method)])
    error_message = "scheduled_rules incident.grouping.entity_matching_method must be AnyAlert, Selected or AllEntities."
  }
  validation {
    condition = alltrue([
      for rule in values(var.scheduled_rules) :
      length(rule.entity_mappings) <= 10 && alltrue([
        for mapping in rule.entity_mappings :
        contains(["Account", "AzureResource", "CloudApplication", "DNS", "File", "FileHash", "Host", "IP", "Mailbox", "MailCluster", "MailMessage", "Malware", "Process", "RegistryKey", "RegistryValue", "SecurityGroup", "SubmissionMail", "URL"], mapping.entity_type) &&
        length(mapping.field_mappings) >= 1 && length(mapping.field_mappings) <= 3
      ])
    ])
    error_message = "scheduled_rules allow at most 10 entity_mappings, each a supported entity_type with 1 to 3 field_mappings."
  }
  validation {
    condition     = alltrue([for rule in values(var.scheduled_rules) : alltrue([for source in rule.requires_sources : contains(["azure_activity", "entra_audit_logs", "entra_signin_logs", "common_security_log", "security_alert", "threat_intelligence_indicator", "office_activity", "syslog", "windows_security_events", "azure_diagnostics"], source)])])
    error_message = "scheduled_rules requires_sources entries must be known sources (see externally_provided_sources)."
  }
}

variable "nrt_rules" {
  description = "Near-real-time analytics rules (run about every minute) keyed by stable name. Use sparingly: Microsoft limits how many NRT rules a workspace can hold and restricts what their queries may contain - check the current limits before adding one."
  type = map(object({
    display_name         = string
    description          = optional(string)
    severity             = string
    query                = string
    tactics              = optional(set(string), [])
    techniques           = optional(set(string), [])
    enabled              = optional(bool, true)
    suppression_duration = optional(string)
    custom_details       = optional(map(string), {})
    event_grouping       = optional(string, "SingleAlert")
    entity_mappings = optional(list(object({
      entity_type = string
      field_mappings = list(object({
        identifier  = string
        column_name = string
      }))
    })), [])
    incident = optional(object({
      create = optional(bool, true)
      grouping = optional(object({
        enabled                 = optional(bool, true)
        lookback_duration       = optional(string, "PT5M")
        reopen_closed_incidents = optional(bool, false)
        entity_matching_method  = optional(string, "AnyAlert")
        by_entities             = optional(list(string), [])
        by_alert_details        = optional(list(string), [])
        by_custom_details       = optional(list(string), [])
      }), {})
    }), {})
    requires_sources = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.nrt_rules) : can(regex("^[a-z0-9][a-z0-9_-]{0,62}$", key))])
    error_message = "nrt_rules keys must be lowercase letters, numbers, hyphens or underscores."
  }
  validation {
    condition     = alltrue([for rule in values(var.nrt_rules) : contains(["High", "Medium", "Low", "Informational"], rule.severity)])
    error_message = "nrt_rules[*].severity must be High, Medium, Low or Informational."
  }
  validation {
    condition     = alltrue([for rule in values(var.nrt_rules) : length(trimspace(rule.query)) > 0 && length(rule.display_name) > 0])
    error_message = "nrt_rules need a non-empty display_name and query."
  }
  validation {
    condition     = alltrue([for rule in values(var.nrt_rules) : contains(["AlertPerResult", "SingleAlert"], rule.event_grouping)])
    error_message = "nrt_rules[*].event_grouping must be AlertPerResult or SingleAlert."
  }
  validation {
    condition = alltrue([
      for rule in values(var.nrt_rules) :
      length(rule.entity_mappings) <= 5 && alltrue([
        for mapping in rule.entity_mappings : length(mapping.field_mappings) >= 1 && length(mapping.field_mappings) <= 3
      ])
    ])
    error_message = "nrt_rules allow at most 5 entity_mappings, each with 1 to 3 field_mappings."
  }
  validation {
    condition     = alltrue([for rule in values(var.nrt_rules) : alltrue([for source in rule.requires_sources : contains(["azure_activity", "entra_audit_logs", "entra_signin_logs", "common_security_log", "security_alert", "threat_intelligence_indicator", "office_activity", "syslog", "windows_security_events", "azure_diagnostics"], source)])])
    error_message = "nrt_rules requires_sources entries must be known sources (see externally_provided_sources)."
  }
}

variable "microsoft_incident_rules" {
  description = "Microsoft security incident creation rules: turn alerts from a Microsoft security product into Sentinel incidents. This is the usual way Defender alerts reach the SOC queue."
  type = map(object({
    display_name                = string
    description                 = optional(string)
    product_filter              = string
    severity_filter             = set(string)
    display_name_filter         = optional(set(string), [])
    display_name_exclude_filter = optional(set(string), [])
    enabled                     = optional(bool, true)
    requires_sources            = optional(list(string), ["security_alert"])
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.microsoft_incident_rules) : can(regex("^[a-z0-9][a-z0-9_-]{0,62}$", key))])
    error_message = "microsoft_incident_rules keys must be lowercase letters, numbers, hyphens or underscores."
  }
  validation {
    condition = alltrue([
      for rule in values(var.microsoft_incident_rules) :
      contains([
        "Azure Active Directory Identity Protection", "Azure Advanced Threat Protection", "Azure Security Center",
        "Azure Security Center for IoT", "Microsoft Cloud App Security", "Microsoft Defender Advanced Threat Protection",
        "Office 365 Advanced Threat Protection",
      ], rule.product_filter)
    ])
    error_message = "microsoft_incident_rules[*].product_filter must be one of the provider-supported product names (for example Azure Security Center for Defender for Cloud)."
  }
  validation {
    condition = alltrue([
      for rule in values(var.microsoft_incident_rules) :
      length(rule.severity_filter) > 0 && alltrue([for severity in rule.severity_filter : contains(["High", "Medium", "Low", "Informational"], severity)])
    ])
    error_message = "microsoft_incident_rules[*].severity_filter needs at least one of High, Medium, Low, Informational."
  }
}

variable "template_rules" {
  description = "Rules created from a Microsoft-provided template: fusion (multistage attack detection), threat_intelligence (TI mapping) or ml_behavior_analytics. The template GUID comes from the workspace's alert rule templates (README shows the az rest command); it is never guessed."
  type = map(object({
    kind                = string
    alert_rule_template = string
    enabled             = optional(bool, true)
    requires_sources    = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.template_rules) : can(regex("^[a-z0-9][a-z0-9_-]{0,62}$", key))])
    error_message = "template_rules keys must be lowercase letters, numbers, hyphens or underscores."
  }
  validation {
    condition     = alltrue([for rule in values(var.template_rules) : contains(["fusion", "threat_intelligence", "ml_behavior_analytics"], rule.kind)])
    error_message = "template_rules[*].kind must be fusion, threat_intelligence or ml_behavior_analytics."
  }
  validation {
    condition     = alltrue([for rule in values(var.template_rules) : can(regex("(?i)^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", rule.alert_rule_template))])
    error_message = "template_rules[*].alert_rule_template must be the template GUID."
  }
}

variable "anomaly_rules" {
  description = "Built-in Sentinel anomaly rules by display name. Mode Flighting is the safe way to evaluate an anomaly rule before Production. Azure cannot delete an anomaly rule, so removing one here only disables it."
  type = map(object({
    display_name = string
    mode         = optional(string, "Flighting")
    enabled      = optional(bool, true)
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.anomaly_rules) : can(regex("^[a-z0-9][a-z0-9_-]{0,62}$", key))])
    error_message = "anomaly_rules keys must be lowercase letters, numbers, hyphens or underscores."
  }
  validation {
    condition     = alltrue([for rule in values(var.anomaly_rules) : contains(["Production", "Flighting"], rule.mode)])
    error_message = "anomaly_rules[*].mode must be Production or Flighting."
  }
}

variable "baseline_content" {
  description = "Opt-in identity and governance detections shipped with the pattern (new Global Administrator, Owner assigned, PIM activation, management-group/policy change, password spray). Off by default: Security Operations owns detection priorities, so this is a starting library, not a mandate. Every baseline rule declares its required telemetry, so enabling it without the matching exports fails the plan."
  type = object({
    enabled = optional(bool, false)
    exclude = optional(set(string), [])
  })
  default = {}
}

# -----------------------------------------------------------------------------
# Automation rules and watchlists
# -----------------------------------------------------------------------------

variable "automation_rules" {
  description = "Sentinel automation rules (triage, enrichment, routing). conditions are AND-ed property tests; analytic_rule_keys scopes the rule to rules created by this pattern. A rule needs at least one action. Playbook actions need the Sentinel service principal to hold Microsoft Sentinel Automation Contributor on the playbook's resource group (outside this pattern)."
  type = map(object({
    display_name  = string
    order         = number
    enabled       = optional(bool, true)
    triggers_on   = optional(string, "Incidents")
    triggers_when = optional(string, "Created")
    expiration    = optional(string)
    conditions = optional(list(object({
      property = string
      operator = string
      values   = list(string)
    })), [])
    analytic_rule_keys = optional(list(string), [])
    modify_incident = optional(list(object({
      order                  = number
      status                 = optional(string)
      severity               = optional(string)
      labels                 = optional(list(string))
      owner_id               = optional(string)
      classification         = optional(string)
      classification_comment = optional(string)
    })), [])
    incident_tasks = optional(list(object({
      order       = number
      title       = string
      description = optional(string)
    })), [])
    playbooks = optional(list(object({
      order        = number
      logic_app_id = string
      tenant_id    = optional(string)
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.automation_rules) : can(regex("^[a-z0-9][a-z0-9_-]{0,62}$", key))])
    error_message = "automation_rules keys must be lowercase letters, numbers, hyphens or underscores (a stable UUID is derived from the key)."
  }
  validation {
    condition     = alltrue([for rule in values(var.automation_rules) : rule.order >= 1 && rule.order <= 1000 && floor(rule.order) == rule.order])
    error_message = "automation_rules[*].order must be a whole number from 1 to 1000."
  }
  validation {
    condition     = length(distinct([for rule in values(var.automation_rules) : rule.order])) == length(var.automation_rules)
    error_message = "automation_rules orders must be unique so execution order is deterministic."
  }
  validation {
    condition     = alltrue([for rule in values(var.automation_rules) : contains(["Incidents", "Alerts"], rule.triggers_on) && contains(["Created", "Updated"], rule.triggers_when)])
    error_message = "automation_rules triggers_on must be Incidents or Alerts and triggers_when must be Created or Updated."
  }
  validation {
    condition = alltrue([
      for rule in values(var.automation_rules) :
      length(rule.modify_incident) + length(rule.incident_tasks) + length(rule.playbooks) > 0
    ])
    error_message = "Each automation rule needs at least one action: modify_incident, incident_tasks or playbooks."
  }
  validation {
    condition = alltrue([
      for rule in values(var.automation_rules) :
      length(distinct(concat(
        [for action in rule.modify_incident : action.order],
        [for action in rule.incident_tasks : action.order],
        [for action in rule.playbooks : action.order],
      ))) == length(rule.modify_incident) + length(rule.incident_tasks) + length(rule.playbooks)
    ])
    error_message = "Action orders within one automation rule must be unique."
  }
  validation {
    condition = alltrue([
      for rule in values(var.automation_rules) :
      alltrue([for condition in rule.conditions :
        contains(["Equals", "NotEquals", "Contains", "NotContains", "StartsWith", "NotStartsWith", "EndsWith", "NotEndsWith"], condition.operator) &&
        length(condition.values) > 0 &&
        contains([
          "IncidentTitle", "IncidentDescription", "IncidentSeverity", "IncidentStatus", "IncidentRelatedAnalyticRuleIds",
          "IncidentTactics", "IncidentLabel", "IncidentProviderName", "IncidentUpdatedBySource", "IncidentCustomDetailsKey",
          "IncidentCustomDetailsValue", "AccountAadTenantId", "AccountAadUserId", "AccountName", "AccountNTDomain",
          "AccountPUID", "AccountSid", "AccountObjectGuid", "AccountUPNSuffix", "AlertProductNames", "AlertAnalyticRuleIds",
          "AzureResourceResourceId", "AzureResourceSubscriptionId", "CloudApplicationAppId", "CloudApplicationAppName",
          "DNSDomainName", "FileDirectory", "FileName", "FileHashValue", "HostAzureID", "HostName", "HostNetBiosName",
          "HostNTDomain", "HostOSVersion", "IPAddress", "MailboxDisplayName", "MailboxPrimaryAddress", "MailboxUPN",
          "MailMessageDeliveryAction", "MailMessageDeliveryLocation", "MailMessageRecipient", "MailMessageSenderIP",
          "MailMessageSubject", "MailMessageP1Sender", "MailMessageP2Sender", "MalwareCategory", "MalwareName",
          "ProcessCommandLine", "ProcessId", "RegistryKey", "RegistryValueData", "Url",
        ], condition.property)
      ])
    ])
    error_message = "automation_rules conditions need a supported Sentinel property, a supported operator (Equals, NotEquals, Contains, NotContains, StartsWith, NotStartsWith, EndsWith, NotEndsWith) and at least one value."
  }
  validation {
    condition = alltrue([
      for rule in values(var.automation_rules) :
      alltrue([for action in rule.modify_incident :
        (action.status == null ? true : contains(["New", "Active", "Closed"], action.status)) &&
        (action.severity == null ? true : contains(["High", "Medium", "Low", "Informational"], action.severity)) &&
        (action.status == "Closed" ? action.classification != null : action.classification == null) &&
        (action.status == null && action.severity == null && action.labels == null && action.owner_id == null ? false : true)
      ])
    ])
    error_message = "modify_incident actions need at least one of status, severity, labels or owner_id; status must be New, Active or Closed; classification is required with Closed and not allowed otherwise."
  }
  validation {
    condition     = alltrue([for rule in values(var.automation_rules) : alltrue([for playbook in rule.playbooks : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Logic/workflows/[^/]+$", playbook.logic_app_id))])])
    error_message = "automation_rules playbooks need the full Logic App (Microsoft.Logic/workflows) resource ID."
  }
}

variable "watchlists" {
  description = "Reference data for detections (break-glass accounts, privileged users, approved egress IPs, critical assets). items are inline rows; every row must contain the item_search_key column. Large or frequently changing lists belong in a pipeline, not tfvars."
  type = map(object({
    display_name     = string
    description      = optional(string)
    item_search_key  = string
    default_duration = optional(string)
    labels           = optional(list(string), [])
    items            = optional(map(map(string)), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.watchlists) : can(regex("^[a-z0-9][a-z0-9_-]{0,62}$", key))])
    error_message = "watchlists keys must be lowercase letters, numbers, hyphens or underscores (the key is the watchlist alias used in KQL _GetWatchlist())."
  }
  validation {
    condition = alltrue([
      for watchlist in values(var.watchlists) :
      alltrue([for row in values(watchlist.items) : contains(keys(row), watchlist.item_search_key)])
    ])
    error_message = "Every watchlist item must contain its item_search_key column."
  }
}
