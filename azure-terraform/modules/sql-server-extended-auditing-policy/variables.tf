variable "server_id" { type = string }
variable "enabled" {
  type    = bool
  default = true
}
variable "log_monitoring_enabled" {
  type    = bool
  default = false
}
variable "predicate_expression" {
  type    = string
  default = null
}
variable "retention_in_days" {
  type    = number
  default = null
}
variable "audit_actions_and_groups" {
  type    = list(string)
  default = null
}
variable "storage_endpoint" {
  type    = string
  default = null
}
variable "storage_account_access_key" {
  type      = string
  default   = null
  sensitive = true
}
variable "storage_account_access_key_is_secondary" {
  type    = bool
  default = false
}
variable "storage_account_subscription_id" {
  type      = string
  default   = null
  sensitive = true
}
variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
