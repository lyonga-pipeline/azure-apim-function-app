variable "app_config_name" {
  type = string
}
variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string
}
variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}
variable "app_config_sku" {
  type    = string
  default = "standard"
}
variable "app_config_local_auth" {
  type    = bool
  default = false
}
variable "app_config_public_access" {
  type    = string
  default = "Disabled"
}
variable "app_config_purge_protection" {
  type    = bool
  default = true
}
variable "app_config_soft_delete_retention_days" {
  type    = number
  default = 7
}
variable "identity" {
  type    = object({ type = string, identity_ids = optional(list(string), []) })
  default = null
}
variable "encryption" {
  type    = object({ key_vault_key_identifier = string, identity_client_id = string })
  default = null
}
variable "app_config_tags" {
  type    = map(string)
  default = {}
}
