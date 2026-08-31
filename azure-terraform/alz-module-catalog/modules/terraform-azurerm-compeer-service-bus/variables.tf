variable "name" {
  description = "Resource name. Changing this forces a new resource."
  type        = string
}
variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string
}
variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}
variable "sku" {
  type    = string
  default = "Standard"
}
variable "capacity" {
  type    = number
  default = 0
}
variable "premium_messaging_partitions" {
  type    = number
  default = 0
}
variable "minimum_tls_version" {
  type    = string
  default = "1.2"
}
variable "public_network_access_enabled" {
  type    = bool
  default = false
}
variable "local_auth_enabled" {
  type    = bool
  default = false
}
variable "identity" {
  type    = object({ type = string, identity_ids = optional(list(string), []) })
  default = null
}
variable "network_rule_set" {
  type = object({
    default_action                = string
    public_network_access_enabled = optional(bool)
    trusted_services_allowed      = optional(bool, false)
    ip_rules                      = optional(list(string), [])
    network_rules                 = optional(map(object({ subnet_id = string, ignore_missing_vnet_service_endpoint = optional(bool, false) })), {})
  })
  default = null
}
variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
