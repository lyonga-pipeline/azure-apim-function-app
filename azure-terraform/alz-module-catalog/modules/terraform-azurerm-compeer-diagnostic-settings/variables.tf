variable "name" {
  type = string
}
variable "target_resource_id" {
  type = string
}
variable "log_analytics_workspace_id" {
  type    = string
  default = null
}
variable "log_analytics_destination_type" {
  type    = string
  default = null

  validation {
    condition     = var.log_analytics_destination_type == null ? true : contains(["AzureDiagnostics", "Dedicated"], var.log_analytics_destination_type)
    error_message = "log_analytics_destination_type must be AzureDiagnostics or Dedicated when set."
  }
}
variable "storage_account_id" {
  type    = string
  default = null
}
variable "eventhub_authorization_rule_id" {
  type    = string
  default = null
}
variable "eventhub_name" {
  type    = string
  default = null
}
variable "partner_solution_id" {
  type    = string
  default = null
}
variable "logs" {
  type = map(object({
    category       = optional(string)
    category_group = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for log in values(var.logs) :
      (try(log.category, null) != null) != (try(log.category_group, null) != null)
    ])
    error_message = "Each log entry must set exactly one of category or category_group."
  }
}
variable "metrics" {
  type = map(object({
    category = string
    enabled  = optional(bool, true)
  }))
  default = {}
}

variable "timeouts" {
  type = object({
    create = optional(string)
    update = optional(string)
    read   = optional(string)
    delete = optional(string)
  })
  default = {}
}
