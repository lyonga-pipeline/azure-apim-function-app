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
    prevent_destroy            = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for _, group in var.management_groups :
      !(try(group.parent_key, null) != null && try(group.parent_management_group_id, null) != null)
    ])
    error_message = "Set only one of parent_key or parent_management_group_id for each management group."
  }
}
