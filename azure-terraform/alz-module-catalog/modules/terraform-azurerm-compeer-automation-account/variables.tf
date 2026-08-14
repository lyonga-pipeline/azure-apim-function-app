variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create Automation Account"
}

variable "resource_group_location" {
  type        = string
  description = "Location of the resource group"
  default     = "eastus2"
}

variable "automation_account_name" {
  type        = string
  description = "Name of the Automation Account."
}

variable "automation_account_sku" {
  type        = string
  description = "SKU for Automation Account."
  default     = "Basic"
}

variable "local_auth_enabled" {
  type        = bool
  description = "Whether request using non-AAD authentication are blocked."
  default     = true
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether public network access is allowed for autiomation account."
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) A mapping of tags to assign to the resource."
  nullable    = false
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default     = null
  description = <<-DESCRIPTION
    type = object({
      type         = (Required) The type of the Identity. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned`.
      identity_ids = (Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this OpenAI Account.
    })
  DESCRIPTION
}

variable "create_runbook" {
  type        = bool
  description = "Allows to create Automation Account Runbook."
  default     = true
}

variable "runbook_configuration" {
  type = map(object({
    runbook_name             = string
    runbook_content_filename = string
    runbook_type             = string
    runbook_log_verbose      = bool
    runbook_log_progress     = bool

  }))
  description = "Runbook configuration to create Automation account Runbooks."
  default     = {}
}

variable "create_runbook_webhook" {
  type        = bool
  description = "Whether to create webhook for runbook"
  default     = true
}

variable "webhook_name" {
  type        = string
  description = "Specifies the name of the webhook."
}

variable "expiry_time" {
  type        = string
  description = "Timestamp when the webhook expires. Example Format: `2023-12-31T00:00:00Z`"
}

variable "webhook_enabled" {
  type        = bool
  description = "Enable/Disable Webhook."
  default     = true
}

variable "webhook_parameters" {
  type        = map(string)
  description = "URI to initiate the webhook."
  default     = {}
}