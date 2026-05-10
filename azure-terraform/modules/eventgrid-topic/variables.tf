variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "input_schema" {
  type    = string
  default = "EventGridSchema"
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
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}
variable "inbound_ip_rules" {
  type = map(object({
    ip_mask = string
    action  = optional(string, "Allow")
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
