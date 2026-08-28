variable "rbac_groups" {
  description = "Entra ID RBAC groups keyed by logical purpose."
  type = map(object({
    display_name            = string
    description             = optional(string)
    mail_nickname           = optional(string)
    members                 = optional(list(string))
    owners                  = optional(set(string))
    prevent_duplicate_names = optional(bool, true)
    assignable_to_role      = optional(bool, false)
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
