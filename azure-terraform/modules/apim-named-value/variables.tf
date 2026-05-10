variable "resource_group_name" {
  type = string
}

variable "api_management_name" {
  type = string
}

variable "named_values" {
  type = map(object({
    display_name = string
    value        = optional(string)
    secret       = optional(bool, false)
    tags         = optional(list(string))
    value_from_key_vault = optional(object({
      secret_id          = string
      identity_client_id = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for value in values(var.named_values) :
      (
        (try(value.value, null) != null || try(value.value_from_key_vault, null) != null) &&
        !(try(value.value, null) != null && try(value.value_from_key_vault, null) != null)
      )
    ])
    error_message = "Each named value must set either value or value_from_key_vault."
  }
}
