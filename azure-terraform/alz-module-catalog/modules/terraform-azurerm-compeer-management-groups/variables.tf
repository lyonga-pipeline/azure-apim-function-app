variable "root_parent_management_group_id" {
  description = "Optional parent management group ID for root-level groups in this module."
  type        = string
  default     = null
}

variable "management_groups" {
  description = "Management groups keyed by the desired management group ID."
  type = map(object({
    display_name               = optional(string)
    parent_key                 = optional(string)
    parent_management_group_id = optional(string)
    subscription_ids           = optional(set(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for _, group in var.management_groups :
      !(try(group.parent_key, null) != null && try(group.parent_management_group_id, null) != null)
    ])
    error_message = "Set only one of parent_key or parent_management_group_id for each management group."
  }

  validation {
    condition = alltrue([
      for _, group in var.management_groups :
      try(group.parent_key, null) == null ? true : contains(keys(var.management_groups), group.parent_key)
    ])
    error_message = "Every parent_key must reference another key in management_groups."
  }

  validation {
    condition = alltrue([
      for key, group in var.management_groups :
      try(group.parent_key, null) != key
    ])
    error_message = "A management group cannot use itself as parent_key."
  }

  validation {
    condition = alltrue([
      for _, group in var.management_groups :
      try(group.parent_key, null) == null ? true : (
        try(var.management_groups[group.parent_key].parent_key, null) == null ? true : (
          try(var.management_groups[var.management_groups[group.parent_key].parent_key].parent_key, null) == null ? true : (
            try(var.management_groups[var.management_groups[var.management_groups[group.parent_key].parent_key].parent_key].parent_key, null) == null ? true : (
              try(var.management_groups[var.management_groups[var.management_groups[var.management_groups[group.parent_key].parent_key].parent_key].parent_key].parent_key, null) == null
            )
          )
        )
      )
    ])
    error_message = "The module supports top-level management groups plus four child levels; shorten the parent_key chain or split the hierarchy."
  }
}
