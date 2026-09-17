variable "log_category_group" {
  description = "Default Azure Monitor diagnostic-setting log category_group. \"allLogs\" is Azure's own \"send everything\" idiom - it avoids hand-enumerating every log category per resource type, and every resource type that supports diagnostic settings at all supports category groups. A caller with a genuine reason to narrow this for one resource still can, by passing its own logs map straight to terraform-azurerm-compeer-diagnostic-settings instead of this profile's default."
  type        = string
  default     = "allLogs"
}

variable "metric_category" {
  description = "Default Azure Monitor diagnostic-setting metric category."
  type        = string
  default     = "AllMetrics"
}

variable "destination_key" {
  description = "Which platform-management output names the default diagnostic destination - a pointer (e.g. \"log_analytics_workspace_id\"), not the resolved ID itself. Keeping this symbolic means the profile stays a stable reference even if the destination's own ID changes, and callers already have the resolved ID available separately (management_log_analytics_workspace_id) without duplicating it here."
  type        = string
  default     = "log_analytics_workspace_id"
}
