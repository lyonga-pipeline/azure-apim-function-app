variable "name" { type = string }
variable "scope" { type = string }
variable "description" {
  type    = string
  default = null
}
variable "role_definition_id" {
  type    = string
  default = null
}
variable "assignable_scopes" {
  type    = list(string)
  default = null
}
variable "permissions" {
  type = map(object({
    actions          = optional(list(string), [])
    not_actions      = optional(list(string), [])
    data_actions     = optional(set(string), [])
    not_data_actions = optional(set(string), [])
  }))
  default = {}

  validation {
    condition     = length(var.permissions) > 0
    error_message = "At least one permissions entry is required."
  }
}
