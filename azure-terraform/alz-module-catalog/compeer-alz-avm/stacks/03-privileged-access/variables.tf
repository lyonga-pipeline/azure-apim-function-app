variable "subscription_id" {
  type = string
}

variable "pim_eligible_role_assignments" {
  description = "PIM eligible assignments for privileged platform roles."
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
  description = "Cloud-only break-glass account UPNs. Terraform does not create these accounts."
  type        = set(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Workspace containing Entra SigninLogs for the break-glass sign-in alert."
  type        = string
  default     = null
}

variable "break_glass_alert" {
  description = "Optional scheduled query alert for any break-glass sign-in."
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

variable "operational_contracts" {
  description = "Additional privileged access controls not represented by native Terraform resources."
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

variable "tags" {
  type    = map(string)
  default = {}
}
