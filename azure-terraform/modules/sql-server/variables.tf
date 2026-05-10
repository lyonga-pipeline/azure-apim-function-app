variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "server_version" {
  type    = string
  default = "12.0"
}
variable "minimum_tls_version" {
  type    = string
  default = "1.2"
}
variable "connection_policy" {
  type    = string
  default = null
}
variable "public_network_access_enabled" {
  type    = bool
  default = false
}
variable "outbound_network_restriction_enabled" {
  type    = bool
  default = false
}
variable "express_vulnerability_assessment_enabled" {
  type    = bool
  default = false
}
variable "azuread_authentication_only" {
  type    = bool
  default = true
}
variable "azuread_administrator" {
  type = object({
    login_username = string
    object_id      = string
  })
  default = null
}
variable "administrator_login" {
  type    = string
  default = null
}
variable "administrator_login_password" {
  type      = string
  default   = null
  sensitive = true
}
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}
variable "primary_user_assigned_identity_id" {
  type    = string
  default = null
}
variable "transparent_data_encryption_key_vault_key_id" {
  type    = string
  default = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
