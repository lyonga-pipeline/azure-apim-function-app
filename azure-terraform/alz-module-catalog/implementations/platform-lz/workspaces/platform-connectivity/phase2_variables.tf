# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Copy this file together with the PHASE 2 section in main.tf and the example.
# =============================================================================
variable "phase2_connection_monitors" {
  type = map(object({
    name                       = string
    network_watcher_id         = string
    source_virtual_machine_id  = string
    destination_address        = string
    destination_port           = number
    source_agent_ready         = bool
    frequency_seconds          = optional(number, 60)
    maximum_round_trip_time_ms = optional(number, 100)
    maximum_failed_percent     = optional(number, 10)
  }))
  default = {}
  validation {
    condition = alltrue([for monitor in values(var.phase2_connection_monitors) :
      monitor.source_agent_ready && monitor.destination_port >= 1 && monitor.destination_port <= 65535 &&
      monitor.frequency_seconds >= 30 && monitor.maximum_failed_percent >= 0 && monitor.maximum_failed_percent <= 100
    ])
    error_message = "Connection Monitor needs its Network Watcher agent/network prerequisites, a valid TCP port and sensible test thresholds."
  }
}
