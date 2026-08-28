variable "subscription_id" { type = string }
variable "location" {
  type    = string
  default = "centralus"
}
variable "environment" { type = string }
variable "prefix" {
  type    = string
  default = "cmp"
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "resource_provider_registrations" {
  description = "Azure resource providers to register as part of the subscription baseline."
  type        = set(string)
  default     = []
}

variable "resource_groups" {
  description = "Standard resource groups to create in the target subscription."
  type = map(object({
    name     = string
    location = optional(string)
    tags     = optional(map(string), {})
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Central Log Analytics workspace resource ID for subscription activity logs."
  type        = string
  default     = null
}

variable "activity_log_categories" {
  type = set(string)
  default = [
    "Administrative",
    "Security",
    "ServiceHealth",
    "Alert",
    "Recommendation",
    "Policy",
    "Autoscale",
    "ResourceHealth"
  ]
}

variable "role_assignments" {
  description = "Subscription, RG, or resource RBAC assignments."
  type = map(object({
    scope                                  = string
    principal_id                           = string
    role_definition_name                   = optional(string)
    role_definition_id                     = optional(string)
    principal_type                         = optional(string)
    description                            = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    skip_service_principal_aad_check       = optional(bool)
    delegated_managed_identity_resource_id = optional(string)
  }))
  default = {}
}

variable "policy_definitions" {
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

variable "subscription_policy_assignments" {
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

variable "defender_enabled" {
  type    = bool
  default = false
}

variable "defender_plans" {
  type = map(object({
    resource_type = string
    tier          = optional(string, "Standard")
    subplan       = optional(string)
    extensions = optional(map(object({
      name                            = string
      additional_extension_properties = optional(map(string))
    })), {})
  }))
  default = {}
}

variable "security_contact" {
  type = object({
    name                = optional(string, "default")
    email               = string
    phone               = optional(string)
    alert_notifications = optional(bool, true)
    alerts_to_admins    = optional(bool, true)
  })
  default = null
}

variable "security_center_settings" {
  type = map(object({
    enabled = bool
  }))
  default = {}
}

variable "soc_posture_contract" {
  type = object({
    defender_standard_enabled     = optional(bool, false)
    sentinel_enabled              = optional(bool, false)
    data_collection_rules_enabled = optional(bool, false)
    security_contact_enabled      = optional(bool, false)
    notes                         = optional(string)
  })
  default = {}
}

variable "budgets" {
  type = map(object({
    name       = string
    amount     = number
    start_date = string
    end_date   = optional(string)
    time_grain = optional(string, "Monthly")
    notifications = optional(map(object({
      enabled        = optional(bool, true)
      operator       = optional(string, "GreaterThanOrEqualTo")
      threshold      = number
      threshold_type = optional(string, "Actual")
      contact_emails = optional(list(string), [])
      contact_groups = optional(list(string), [])
      contact_roles  = optional(list(string), [])
    })), {})
  }))
  default = {}
}

variable "operational_contracts" {
  type = map(object({
    phase                = optional(string, "Phase 1")
    owner                = optional(string)
    enabled              = optional(bool, false)
    cost_disabled        = optional(bool, true)
    implementation_state = optional(string, "contract-only")
    required_controls    = optional(list(string), [])
    evidence_locations   = optional(list(string), [])
    notes                = optional(string)
  }))
  default = {}
}
