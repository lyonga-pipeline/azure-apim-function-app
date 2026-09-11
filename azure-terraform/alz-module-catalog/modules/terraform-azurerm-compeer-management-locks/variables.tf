variable "locks" {
  description = "Azure Resource Manager locks keyed by logical name. Scopes must be subscription, resource group, or resource IDs; management group scopes are not supported by Azure locks."
  type = map(object({
    name       = optional(string)
    scope      = string
    lock_level = optional(string, "CanNotDelete")
    notes      = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for _, lock in var.locks : contains(["CanNotDelete", "ReadOnly"], try(lock.lock_level, "CanNotDelete"))
    ])
    error_message = "lock_level must be CanNotDelete or ReadOnly."
  }

  validation {
    condition = alltrue([
      for _, lock in var.locks : try(lock.name, null) == null ? true : length(trimspace(lock.name)) > 0
    ])
    error_message = "name must be null/omitted or a non-empty string."
  }

  validation {
    condition = alltrue([
      for _, lock in var.locks : length(trimspace(lock.scope)) > 0
    ])
    error_message = "scope must be a non-empty Azure resource ID."
  }

  validation {
    condition = alltrue([
      for _, lock in var.locks : !startswith(lower(trimspace(lock.scope)), "/providers/microsoft.management/managementgroups/")
    ])
    error_message = "Azure resource locks cannot be applied directly to management groups. Use subscription, resource group, or resource scope IDs."
  }
}
