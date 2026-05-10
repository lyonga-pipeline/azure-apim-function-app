variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "storage_data_lake_gen2_filesystem_id" { type = string }
variable "sql_administrator_login" { type = string }
variable "sql_administrator_login_password" {
  type      = string
  sensitive = true
}
variable "managed_virtual_network_enabled" {
  type    = bool
  default = true
}
variable "data_exfiltration_protection_enabled" {
  type    = bool
  default = true
}
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
