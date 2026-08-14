variable "assignments" {
  type = map(object({
    scope                                  = string
    principal_id                           = string
    role_definition_name                   = optional(string)
    role_definition_id                     = optional(string)
    principal_type                         = optional(string)
    description                            = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    skip_service_principal_aad_check       = optional(bool)
    delegated_managed_identity_resource_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for item in values(var.assignments) :
      (
        (try(item.role_definition_name, null) != null || try(item.role_definition_id, null) != null) &&
        !(try(item.role_definition_name, null) != null && try(item.role_definition_id, null) != null)
      )
    ])
    error_message = "Each assignment must set exactly one of role_definition_name or role_definition_id."
  }
}
