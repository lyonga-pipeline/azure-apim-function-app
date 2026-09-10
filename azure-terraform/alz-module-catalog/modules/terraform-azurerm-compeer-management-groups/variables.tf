variable "root_parent_management_group_id" {
  description = "Default Azure parent for top-level groups (those with no parent_key). Accepts a full management group resource ID or null to place them directly under the tenant root group. A per-group parent_management_group_id overrides this for that group."
  type        = string
  default     = null
}

variable "management_groups" {
  description = <<-EOT
    Management groups keyed by the desired management group name/ID. Stable keys keep
    unrelated groups from being replaced when one is added or removed.

    Parenting model, exactly one of:
      - parent_key: another key in this map (builds the in-module hierarchy).
      - parent_management_group_id: a management group that already exists outside
        this module, given as a full resource ID. Use this only for top-level groups
        that must hang off a specific external parent; otherwise leave both unset and
        the group lands under root_parent_management_group_id (or the tenant root).

    subscription_ids: subscriptions to associate directly with this group.
  EOT
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
              try(var.management_groups[var.management_groups[var.management_groups[var.management_groups[group.parent_key].parent_key].parent_key].parent_key].parent_key, null) == null ? true : (
                try(var.management_groups[var.management_groups[var.management_groups[var.management_groups[var.management_groups[group.parent_key].parent_key].parent_key].parent_key].parent_key].parent_key, null) == null
              )
            )
          )
        )
      )
    ])
    error_message = "The module supports top-level management groups plus five child levels; shorten the parent_key chain or split the hierarchy."
  }
}
