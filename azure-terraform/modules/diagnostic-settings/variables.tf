variable "name" { type = string }
variable "target_resource_id" { type = string }
variable "log_analytics_workspace_id" {
  type    = string
  default = null
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
