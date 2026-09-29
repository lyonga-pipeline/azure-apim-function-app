variable "assignments" {
  type = map(object({
    name                                   = optional(string)
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

  validation {
    # azurerm_role_assignment's own documented principal_type values - a
    # fourth value ("ForeignGroup"/"Device") is NOT supported by this
    # resource and only fails at apply, potentially after sibling
    # assignments in the same for_each already succeeded.
    condition = alltrue([
      for item in values(var.assignments) :
      try(item.principal_type, null) == null ? true : contains(["User", "Group", "ServicePrincipal"], item.principal_type)
    ])
    error_message = "Each assignment's principal_type, when set, must be User, Group, or ServicePrincipal."
  }
}
