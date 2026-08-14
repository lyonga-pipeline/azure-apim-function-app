variable "locks" {
  description = "Management locks keyed by logical name."
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
}
