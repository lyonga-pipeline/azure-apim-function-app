variable "management_subscription_id" { type = string }
variable "root_parent_management_group_id" { type = string }
variable "architecture_name" {
  type    = string
  default = "alz"
}

variable "location" {
  type    = string
  default = "centralus"
}

variable "enable_telemetry" {
  type    = bool
  default = true
}
variable "management_group_role_assignments" {
  type    = map(object({ principal_id = string, role_definition_id_or_name = string }))
  default = {}
}


variable "custom_role_definitions" {
  description = "Compeer custom RBAC definitions. Permission sets are organization-specific."
  type = map(object({
    name              = string
    description       = string
    actions           = set(string)
    not_actions       = optional(set(string), [])
    data_actions      = optional(set(string), [])
    not_data_actions  = optional(set(string), [])
    assignable_scopes = set(string)
  }))
  default = {}
}

variable "policy_definitions" {
  description = "Compeer custom Azure Policy definitions keyed by logical name."
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
  description = "Compeer custom Azure Policy initiatives keyed by logical name."
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

variable "management_group_policy_assignments" {
  description = "Management-group-scoped policy and initiative assignments."
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

variable "subscription_policy_assignments" {
  description = "Subscription-scoped policy and initiative assignments."
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

variable "resource_group_policy_assignments" {
  description = "Resource-group-scoped policy and initiative assignments."
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

variable "policy_exemptions" {
  description = "Time-bound Azure Policy exemptions. Use sparingly and require expiry metadata."
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
}
