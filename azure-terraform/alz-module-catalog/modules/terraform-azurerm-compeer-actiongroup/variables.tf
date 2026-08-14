variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "resource_group_location" {
  type        = string
  description = "Resource group location."
  default     = "northcentralus"
}

variable "action_group_name" {
  type        = string
  description = "The name of the Action Group."
}

variable "action_group_short_name" {
  type        = string
  description = "The short name of the action group."
}

variable "enable_action_group" {
  type        = bool
  description = "Whether this action group is enabled."
  default     = true
}

variable "actiongrp_email_receiver" {
  type = set(object({
    name                    = string
    email_address           = string
    use_common_alert_schema = optional(bool)
  }))
  description = "Block defined to send alert to email ids."
  default     = []
}

variable "actiongrp_automation_runbook_receiver" {
  type = set(object({
    name                    = string
    automation_account_id   = string
    runbook_name            = string
    webhook_resource_id     = string
    is_global_runbook       = bool
    service_uri             = string
    use_common_alert_schema = optional(bool)
  }))
  description = <<-DESCRIPTION
    type = set(object({
    name                    = string - (Required) The name of the automation runbook receiver.
    automation_account_id   = string - (Required) The automation account ID which holds this runbook and authenticates to Azure resources.
    runbook_name            = string - (Required) The name for this runbook.
    webhook_resource_id     = string - (Required) The resource id for webhook linked to this runbook.
    is_global_runbook       = bool - (Required) Indicates whether this instance is global runbook.
    service_uri             = string  - (Required) The URI where webhooks should be sent.
    use_common_alert_schema = optional(bool) - (Optional) Enables or disables the common alert schema. Default is true.
  }))
  DESCRIPTION
  default     = []
}