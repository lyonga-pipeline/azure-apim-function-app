variable "policy_definitions" {
  description = "Custom Azure Policy definitions keyed by logical name."
  type = map(object({
    name                = optional(string)
    policy_type         = optional(string, "Custom")
    mode                = optional(string, "All")
    display_name        = string
    description         = optional(string)
    management_group_id = optional(string)
    metadata            = optional(any)
    parameters          = optional(any)
    policy_rule         = any
  }))
  default = {}
}

variable "policy_set_definitions" {
  description = "Policy initiatives keyed by logical name."
  type = map(object({
    name                = optional(string)
    policy_type         = optional(string, "Custom")
    display_name        = string
    description         = optional(string)
    management_group_id = optional(string)
    metadata            = optional(any)
    parameters          = optional(any)
    policy_definition_references = list(object({
      policy_definition_id  = optional(string)
      policy_definition_key = optional(string)
      reference_id          = optional(string)
      parameter_values      = optional(any)
      policy_group_names    = optional(list(string))
      group_names           = optional(list(string))
    }))
  }))
  default = {}
}

variable "management_group_assignments" {
  description = "Management-group-scoped policy or initiative assignments."
  type = map(object({
    name                      = optional(string)
    management_group_id       = string
    policy_definition_id      = optional(string)
    policy_definition_key     = optional(string)
    policy_set_definition_key = optional(string)
    display_name              = optional(string)
    description               = optional(string)
    enforce                   = optional(bool, true)
    location                  = optional(string)
    parameters                = optional(any)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    non_compliance_messages = optional(map(string), {})
  }))
  default = {}
}

variable "subscription_assignments" {
  description = "Subscription-scoped policy or initiative assignments."
  type = map(object({
    name                      = optional(string)
    subscription_id           = string
    policy_definition_id      = optional(string)
    policy_definition_key     = optional(string)
    policy_set_definition_key = optional(string)
    display_name              = optional(string)
    description               = optional(string)
    enforce                   = optional(bool, true)
    location                  = optional(string)
    parameters                = optional(any)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    non_compliance_messages = optional(map(string), {})
  }))
  default = {}
}

variable "resource_group_assignments" {
  description = "Resource-group-scoped policy or initiative assignments."
  type = map(object({
    name                      = optional(string)
    resource_group_id         = string
    policy_definition_id      = optional(string)
    policy_definition_key     = optional(string)
    policy_set_definition_key = optional(string)
    display_name              = optional(string)
    description               = optional(string)
    enforce                   = optional(bool, true)
    location                  = optional(string)
    parameters                = optional(any)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    non_compliance_messages = optional(map(string), {})
  }))
  default = {}
}

variable "exemptions" {
  description = "Policy exemptions. Use sparingly and require expiration metadata."
  type = map(object({
    scope_type            = string
    management_group_id   = optional(string)
    subscription_id       = optional(string)
    resource_group_id     = optional(string)
    policy_assignment_id  = string
    exemption_category    = optional(string, "Waiver")
    display_name          = optional(string)
    description           = optional(string)
    expires_on            = optional(string)
    metadata              = optional(any)
    policy_definition_ids = optional(list(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for _, exemption in var.exemptions :
      contains(["management_group", "subscription", "resource_group"], exemption.scope_type)
    ])
    error_message = "exemptions.scope_type must be management_group, subscription, or resource_group."
  }
}
