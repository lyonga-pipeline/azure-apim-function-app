variable "pim_eligible_role_assignments" {
  description = <<-EOT
    PIM *eligible* (not active) role assignments for privileged platform roles —
    design doc Phase 2 Steps 6-7 ("Deploy PIM" / "Convert active to eligible").
    Principals are almost always the AZ-*-Admins groups from platform-authorization,
    not individuals.

    role_definition_id is the full role definition resource ID, e.g.
    "/providers/Microsoft.Management/managementGroups/platform-mg/providers/Microsoft.Authorization/roleDefinitions/<guid>"
    or the tenant-level "/providers/Microsoft.Authorization/roleDefinitions/<guid>".
  EOT
  type = map(object({
    scope              = string
    role_definition_id = string
    principal_id       = string
    justification      = optional(string)
    condition          = optional(string)
    condition_version  = optional(string)
    schedule = optional(object({
      start_date_time = optional(string)
      expiration = optional(object({
        duration_days  = optional(number)
        duration_hours = optional(number)
        end_date_time  = optional(string)
      }))
    }))
    ticket = optional(object({
      number = optional(string)
      system = optional(string)
    }))
  }))
  default = {}
}

variable "break_glass_user_principal_names" {
  description = "Cloud-only break-glass account UPNs. Terraform does NOT create these accounts (see operational_contracts.break_glass_accounts) — this list only feeds the sign-in alert."
  type        = set(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Workspace holding Entra SigninLogs, required when break_glass_alert.enabled is true."
  type        = string
  default     = null
}

variable "break_glass_alert" {
  description = "Optional scheduled-query alert that fires on ANY break-glass account sign-in (design doc Phase 2 Step 9 / Phase 7 detection)."
  type = object({
    enabled               = optional(bool, false)
    name                  = optional(string, "break-glass-signin")
    display_name          = optional(string)
    resource_group_name   = optional(string)
    location              = optional(string, "centralus")
    severity              = optional(number, 0)
    evaluation_frequency  = optional(string, "PT5M")
    window_duration       = optional(string, "PT5M")
    action_group_ids      = optional(list(string), [])
    skip_query_validation = optional(bool, true)
  })
  default = {}
}

variable "role_management_policies" {
  description = <<-EOT
    PIM *activation policy* settings (approval, MFA-on-activation, max
    duration, notifications) for the roles in pim_eligible_role_assignments —
    design doc Phase 2 Step 6. Pair each entry's role_definition_id + scope
    with the matching pim_eligible_role_assignments entry.
  EOT
  type = map(object({
    role_definition_id = string
    scope              = string

    activation_rules = optional(object({
      maximum_duration                                   = optional(string)
      require_approval                                   = optional(bool)
      require_justification                              = optional(bool)
      require_multifactor_authentication                 = optional(bool)
      require_ticket_info                                = optional(bool)
      required_conditional_access_authentication_context = optional(string)
      approvers = optional(list(object({
        object_id = string
        type      = string
      })), [])
    }))

    active_assignment_rules = optional(object({
      expiration_required                = optional(bool)
      expire_after                       = optional(string)
      require_justification              = optional(bool)
      require_multifactor_authentication = optional(bool)
      require_ticket_info                = optional(bool)
    }))

    eligible_assignment_rules = optional(object({
      expiration_required = optional(bool)
      expire_after        = optional(string)
    }))

    notification_rules = optional(map(map(object({
      default_recipients    = bool
      notification_level    = optional(string, "All")
      additional_recipients = optional(set(string), [])
    }))), {})
  }))
  default = {}
}

variable "operational_contracts" {
  description = "Privileged-access controls not represented by native Terraform resources (Conditional Access for admins, PAW/secure admin environment)."
  type = map(object({
    phase                = optional(string, "Phase 2")
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

variable "tags" {
  description = "Tags applied to the alert rule."
  type        = map(string)
  default     = {}
}
