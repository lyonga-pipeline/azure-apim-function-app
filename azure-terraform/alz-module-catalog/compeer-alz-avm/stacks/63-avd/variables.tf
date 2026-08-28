variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "centralus"
}

variable "resource_group_name" {
  type = string
}

variable "application_group" {
  type = object({
    name = string
    type = optional(string, "Desktop")
  })
}

variable "host_pool" {
  type = object({
    name               = string
    type               = optional(string, "Pooled")
    load_balancer_type = optional(string, "BreadthFirst")
  })
}

variable "workspace" {
  type = object({
    name                          = string
    public_network_access_enabled = optional(bool, false)
  })
}

variable "scaling_plan" {
  type = object({
    name      = string
    time_zone = optional(string, "Central Standard Time")
    schedule = list(object({
      days_of_week                         = set(string)
      name                                 = string
      off_peak_load_balancing_algorithm    = string
      off_peak_start_time                  = string
      peak_load_balancing_algorithm        = string
      peak_start_time                      = string
      ramp_down_capacity_threshold_percent = number
      ramp_down_force_logoff_users         = bool
      ramp_down_load_balancing_algorithm   = string
      ramp_down_minimum_hosts_percent      = number
      ramp_down_notification_message       = string
      ramp_down_start_time                 = string
      ramp_down_stop_hosts_when            = string
      ramp_down_wait_time_minutes          = number
      ramp_up_capacity_threshold_percent   = optional(number)
      ramp_up_load_balancing_algorithm     = string
      ramp_up_minimum_hosts_percent        = optional(number)
      ramp_up_start_time                   = string
    }))
  })
}

variable "private_endpoints" {
  description = "AVD private endpoint map passed to the AVM host pool module."
  type        = any
  default     = {}
}

variable "role_assignments" {
  description = "AVD role assignments passed to the AVM module."
  type        = any
  default     = {}
}

variable "enable_telemetry" {
  type    = bool
  default = true
}

variable "operational_contracts" {
  description = "AVD/Citrix session host, image, and profile decisions outside the management-plane module."
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
  default = {
    avd_session_hosts = {
      phase                = "Phase 2"
      implementation_state = "contract-only"
      required_controls    = ["golden image", "FSLogix profile storage", "domain join path", "user assignment model", "diagnostic settings"]
      notes                = "WKL-06 management plane is AVM-backed here; session host deployment and diagnostics depend on the final AVD vs Citrix migration design."
    }
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
