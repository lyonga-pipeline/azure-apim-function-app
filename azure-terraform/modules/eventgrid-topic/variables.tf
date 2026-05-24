variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "input_schema" {
  type    = string
  default = "EventGridSchema"

  validation {
    condition     = contains(["EventGridSchema", "CloudEventSchemaV1_0", "CustomEventSchema"], var.input_schema)
    error_message = "input_schema must be EventGridSchema, CloudEventSchemaV1_0, or CustomEventSchema."
  }
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

  validation {
    condition = alltrue([
      for rule in values(var.inbound_ip_rules) :
      contains(["Allow"], try(rule.action, "Allow"))
    ])
    error_message = "Each inbound_ip_rules action must be Allow."
  }
}
variable "tags" {
  type    = map(string)
  default = {}
}
