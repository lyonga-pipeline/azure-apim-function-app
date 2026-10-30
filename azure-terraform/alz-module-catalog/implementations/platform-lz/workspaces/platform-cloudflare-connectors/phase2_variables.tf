# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Copy this file together with the PHASE 2 section in main.tf and the example.
# =============================================================================
variable "phase2_agents" {
  description = "VM-owner-only AMA/inventory configuration keyed by this root's VM logical keys. VM IDs are resolved here, never accepted from another subscription."
  type = map(object({
    os_type                                 = string
    managed_identity_id                     = string
    identity_and_network_ready              = bool
    install_agent                           = optional(bool, true)
    existing_agent_confirmed                = optional(bool, false)
    data_collection_rules                   = map(string)
    private_ingestion_enabled               = optional(bool, false)
    data_collection_endpoint_id             = optional(string)
    manage_endpoint_association             = optional(bool, true)
    external_endpoint_association_confirmed = optional(bool, false)
    private_link_scope_ready                = optional(bool, false)
    change_tracking_enabled                 = optional(bool, false)
    change_tracking_dcr_ready               = optional(bool, false)
    change_tracking_dcr_key                 = optional(string)
    change_tracking_version                 = optional(string, "2.20")
  }))
  default = {}
  validation {
    condition = alltrue(concat(
      [for key in keys(var.phase2_agents) : !strcontains(key, "/")],
      flatten([for agent in values(var.phase2_agents) : [for key in keys(agent.data_collection_rules) : !strcontains(key, "/")]])
    ))
    error_message = "Agent and DCR logical keys must not contain '/' (reserved stable-key separator)."
  }
  validation {
    condition = alltrue([for agent in values(var.phase2_agents) :
      contains(["Windows", "Linux"], agent.os_type) && agent.identity_and_network_ready &&
      (agent.install_agent || agent.existing_agent_confirmed) && length(agent.data_collection_rules) > 0 &&
      (!agent.change_tracking_enabled || (agent.change_tracking_dcr_ready && try(contains(keys(agent.data_collection_rules), agent.change_tracking_dcr_key), false))) &&
      (!agent.private_ingestion_enabled || (agent.data_collection_endpoint_id != null && agent.private_link_scope_ready)) &&
      (agent.data_collection_endpoint_id == null ? true : (agent.manage_endpoint_association || agent.external_endpoint_association_confirmed)) &&
      can(regex("(?i)/providers/Microsoft.ManagedIdentity/userAssignedIdentities/[^/]+$", agent.managed_identity_id))
    ])
    error_message = "Agents need valid VM/UAMI/DCR inputs and readiness. Private ingestion requires a DCE/AMPLS and explicit association ownership. Inventory needs an associated Change Tracking DCR key."
  }
}

variable "phase2_agent_ownership_confirmed" {
  description = "Confirm no other state owns these AMA/Change Tracking extensions or DCR/DCE associations; do not use this flag instead of a state handoff."
  type        = bool
  default     = false
}
