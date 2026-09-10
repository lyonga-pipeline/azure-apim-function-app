variable "rbac_groups" {
  description = <<-EOT
    Entra security groups that are the ONLY principals granted Azure RBAC in the
    landing zone (design doc Phase 1 Step 5 / Phase 3 Step 5 — "User -> Group ->
    Role -> Scope, never User -> Role"). Keyed by a stable short key; display_name
    is the Entra group name (e.g. "AZ-PLT-Readers").

    members / owners are Entra object IDs. Prefer leaving members empty here and
    governing membership through the joiner/mover/leaver process or Entra
    entitlement management; Terraform still owns the group object and its RBAC.
  EOT
  type = map(object({
    display_name            = string
    description             = optional(string)
    mail_nickname           = optional(string)
    members                 = optional(list(string))
    owners                  = optional(list(string))
    assignable_to_role      = optional(bool, false)
    prevent_duplicate_names = optional(bool, true)
  }))
  default = {}
}

variable "custom_role_definitions" {
  description = "Custom Azure role definitions created at a management-group scope. Keep to a minimum — prefer built-in roles (design doc Phase 3 Step 4)."
  type = map(object({
    name               = string
    scope              = string
    description        = optional(string)
    role_definition_id = optional(string)
    assignable_scopes  = optional(list(string))
    permissions = map(object({
      actions          = optional(list(string), [])
      not_actions      = optional(list(string), [])
      data_actions     = optional(set(string), [])
      not_data_actions = optional(set(string), [])
    }))
  }))
  default = {}
}

variable "role_assignments" {
  description = <<-EOT
    Group-to-role-to-scope assignments (the RBAC Assignment Matrix). scope is a
    full resource ID (management group, subscription, or resource group).
    Set exactly one of group_key (an rbac_groups key) or principal_id, and
    exactly one of role_definition_name (a built-in role) or role_definition_key
    (a custom_role_definitions key).
  EOT
  type = map(object({
    name                             = optional(string)
    scope                            = string
    group_key                        = optional(string)
    principal_id                     = optional(string)
    principal_type                   = optional(string, "Group")
    role_definition_name             = optional(string)
    role_definition_key              = optional(string)
    description                      = optional(string)
    condition                        = optional(string)
    condition_version                = optional(string)
    skip_service_principal_aad_check = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for ra in values(var.role_assignments) :
      length(compact([try(ra.group_key, null), try(ra.principal_id, null)])) == 1
    ])
    error_message = "Each role assignment must set exactly one of group_key or principal_id."
  }

  validation {
    condition = alltrue([
      for ra in values(var.role_assignments) :
      length(compact([try(ra.role_definition_name, null), try(ra.role_definition_key, null)])) == 1
    ])
    error_message = "Each role assignment must set exactly one of role_definition_name or role_definition_key."
  }
}

variable "operational_contracts" {
  description = "Identity / RBAC controls that are NOT provisioned here (break-glass accounts, Conditional Access, PIM policy settings, access reviews) — tracked with rationale. See terraform-azurerm-compeer-operational-contracts."
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
