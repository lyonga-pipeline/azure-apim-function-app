variable "name" {
  description = "Name of the custom role. Changing this forces a new resource."
  type        = string
}
variable "scope" {
  description = "Scope at which the role definition is created (management group, subscription, or resource group ID)."
  type        = string
}
variable "description" {
  description = "Description of the custom role."
  type        = string
  default     = null
}
variable "role_definition_id" {
  description = "Optional fixed GUID for the role. Leave null to let Azure generate one."
  type        = string
  default     = null
}
variable "assignable_scopes" {
  description = "Scopes the role can be assigned at. Defaults to [scope] when null."
  type        = list(string)
  default     = null
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
