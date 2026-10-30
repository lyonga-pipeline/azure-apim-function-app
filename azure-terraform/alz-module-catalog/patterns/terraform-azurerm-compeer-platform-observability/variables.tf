variable "resource_group_name" { type = string }
variable "location" {
  type    = string
  default = "centralus"
}
variable "log_analytics_workspace_id" { type = string }
variable "action_group_ids" {
  type    = set(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}

# PHASE2 NEW: v5 2.1 OBS-04. Queries must be tested against the real enabled tables.
variable "log_alerts" {
  type = map(object({
    name                  = string
    query                 = string
    description           = string
    severity              = optional(number, 2)
    evaluation_frequency  = optional(string, "PT5M")
    window_duration       = optional(string, "PT30M")
    aggregation           = optional(string, "Count")
    metric_measure_column = optional(string)
    operator              = optional(string, "GreaterThan")
    threshold             = optional(number, 0)
    enabled               = optional(bool, true)
    dimensions = optional(map(object({
      name     = string
      operator = optional(string, "Include")
      values   = list(string)
    })), {})
  }))
  default = {}
  validation {
    condition     = alltrue([for alert in values(var.log_alerts) : alert.severity >= 0 && alert.severity <= 4 && length(trimspace(alert.query)) > 0])
    error_message = "Log alerts require a non-empty reviewed KQL query and severity 0-4."
  }
}

# PHASE2 NEW: v5 2.2 OBS-06 and 8.3 PLT-05. DCR creation already exists in platform-management.
variable "agents" {
  type = map(object({
    virtual_machine_id                      = string
    os_type                                 = string
    managed_identity_id                     = string
    identity_and_network_ready              = bool
    install_agent                           = optional(bool, true)
    existing_agent_confirmed                = optional(bool, false)
    data_collection_rules                   = map(string)
    private_ingestion_enabled               = optional(bool, false)
    data_collection_endpoint_id             = optional(string)
    manage_endpoint_association             = optional(bool, true)
    external_endpoint_association_confirmed = optional(bool, false)
    private_link_scope_ready                = optional(bool, false)
    change_tracking_enabled                 = optional(bool, false)
    change_tracking_dcr_ready               = optional(bool, false)
    change_tracking_dcr_key                 = optional(string)
    change_tracking_version                 = optional(string, "2.20")
  }))
  default = {}
  validation {
    condition = alltrue(concat(
      [for key in keys(var.agents) : !strcontains(key, "/")],
      flatten([for agent in values(var.agents) : [for key in keys(agent.data_collection_rules) : !strcontains(key, "/")]])
    ))
    error_message = "Agent and DCR logical keys must not contain '/' (reserved stable-key separator)."
  }
  validation {
    condition = alltrue([for agent in values(var.agents) :
      contains(["Windows", "Linux"], agent.os_type) && agent.identity_and_network_ready &&
      (agent.install_agent || agent.existing_agent_confirmed) && length(agent.data_collection_rules) > 0 &&
      (!agent.change_tracking_enabled || (agent.change_tracking_dcr_ready && try(contains(keys(agent.data_collection_rules), agent.change_tracking_dcr_key), false))) &&
      (!agent.private_ingestion_enabled || (agent.data_collection_endpoint_id != null && agent.private_link_scope_ready)) &&
      (agent.data_collection_endpoint_id == null ? true : (agent.manage_endpoint_association || agent.external_endpoint_association_confirmed)) &&
      can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Compute/virtualMachines/[^/]+$", agent.virtual_machine_id)) &&
      can(regex("(?i)/providers/Microsoft.ManagedIdentity/userAssignedIdentities/[^/]+$", agent.managed_identity_id))
    ])
    error_message = "Agents need valid VM/UAMI/DCR inputs and readiness. Private ingestion requires a DCE/AMPLS and explicit association ownership. Inventory needs an associated Change Tracking DCR key."
  }
}

# PHASE2 NEW: v5 2.8 OBS-07 and 3.5 SEC-14. Existing LAW is referenced, never adopted.
variable "workbooks" {
  type = map(object({
    name         = string
    display_name = string
    data_json    = string
  }))
  default = {}
  validation {
    condition     = alltrue([for workbook in values(var.workbooks) : can(jsondecode(workbook.data_json)) && can(regex("^[0-9a-fA-F-]{36}$", workbook.name))])
    error_message = "Workbooks require a stable UUID name and valid workbook JSON."
  }
}

# PHASE2 NEW: v5 3.8 NET-30. Reuse the subscription/region's existing Network Watcher.
variable "connection_monitors" {
  type = map(object({
    name                       = string
    network_watcher_id         = string
    source_virtual_machine_id  = string
    destination_address        = string
    destination_port           = number
    source_agent_ready         = bool
    frequency_seconds          = optional(number, 60)
    maximum_round_trip_time_ms = optional(number, 100)
    maximum_failed_percent     = optional(number, 10)
  }))
  default = {}
  validation {
    condition = alltrue([for monitor in values(var.connection_monitors) :
      monitor.source_agent_ready && monitor.destination_port >= 1 && monitor.destination_port <= 65535 &&
      monitor.frequency_seconds >= 30 && monitor.maximum_failed_percent >= 0 && monitor.maximum_failed_percent <= 100
    ])
    error_message = "Connection Monitor needs its Network Watcher agent/network prerequisites, a valid TCP port and sensible test thresholds."
  }
}

# PHASE2 NEW: OBS-04 native metrics complement log alerts when ingestion itself fails.
variable "metric_alerts" {
  type = map(object({
    name                     = string
    scopes                   = set(string)
    metric_namespace         = string
    metric_name              = string
    aggregation              = string
    operator                 = string
    threshold                = number
    target_resource_type     = optional(string)
    target_resource_location = optional(string)
    severity                 = optional(number, 2)
    frequency                = optional(string, "PT5M")
    window_size              = optional(string, "PT15M")
    dimensions = optional(map(object({
      name     = string
      operator = optional(string, "Include")
      values   = list(string)
    })), {})
  }))
  default = {}
  validation {
    condition     = alltrue([for alert in values(var.metric_alerts) : length(alert.scopes) > 0 && alert.severity >= 0 && alert.severity <= 4 && (length(alert.scopes) == 1 || (alert.target_resource_type != null && alert.target_resource_location != null))])
    error_message = "Metric alerts require resource scopes and severity 0-4; multiple scopes also need the target resource type and region."
  }
}
