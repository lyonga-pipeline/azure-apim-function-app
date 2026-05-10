variable "resource_group_name" { type = string }
variable "server_name" { type = string }
variable "state" {
  type    = string
  default = "Enabled"
}
variable "disabled_alerts" {
  type    = set(string)
  default = []
}
variable "email_account_admins" {
  type    = bool
  default = true
}
variable "email_addresses" {
  type    = set(string)
  default = []
}
variable "retention_days" {
  type    = number
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
variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
