variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "app_service_plan_id" {
  type    = string
  default = null
}
variable "key_vault_id" {
  type    = string
  default = null
}
variable "key_vault_secret_id" {
  type    = string
  default = null
}
variable "pfx_blob" {
  type      = string
  default   = null
  sensitive = true
}
variable "password" {
  type      = string
  default   = null
  sensitive = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
