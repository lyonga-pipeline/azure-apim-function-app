variable "subscription_id" {
  type        = string
  description = "Execution subscription for governance deployment."
}

variable "root_management_group_id" {
  type        = string
  description = "Tenant root management group id or approved Compeer root management group id."
}

variable "management_groups" {
  type = map(object({
    display_name = string
    parent_key   = optional(string, "root")
  }))
  description = "Management groups keyed by stable purpose."
}

variable "subscription_placements" {
  type = map(object({
    subscription_id      = string
    management_group_key = string
  }))
  description = "Subscriptions placed under the landing-zone management group hierarchy."
  default     = {}
}

