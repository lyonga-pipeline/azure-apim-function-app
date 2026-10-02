variable "name" {
  description = "Name of the user-assigned managed identity. Changing this forces a new resource."
  type        = string

  validation {
    # Microsoft.ManagedIdentity/userAssignedIdentities naming rule: 3-128
    # chars, alphanumerics/hyphens/underscores, must start with a letter or
    # number (verified against Azure's resource-name-rules reference).
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{2,127}$", var.name))
    error_message = "name must be 3-128 characters, alphanumeric/hyphen/underscore only, and start with a letter or number."
  }
}

variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string

  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "resource_group_name must not be empty."
  }
}

variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "location must not be empty."
  }
}

variable "tags" {
  description = "Tags applied to the identity."
  type        = map(string)
  default     = {}
}
