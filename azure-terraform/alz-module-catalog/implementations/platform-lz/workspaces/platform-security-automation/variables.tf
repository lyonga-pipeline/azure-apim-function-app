variable "subscription_id" {
  description = "Existing CSP subscription UUID. Subscription onboarding remains platform-governance owned."
  type        = string
}
# PHASE2 NEW: v5 3.2 SEC-13. Wiring only; the service owner supplies a real rotation handler.
variable "tags" {
  description = "Approved governance tags for a newly created system topic."
  type        = map(string)
  default     = {}
}
variable "secret_rotations" {
  type = map(object({
    name                            = string
    system_topic_name               = string
    create_system_topic             = optional(bool, false)
    system_topic_location           = optional(string, "centralus")
    system_topic_resource_group     = string
    vault_id                        = string
    secret_names                    = set(string)
    function_id                     = string
    function_principal_id           = string
    dead_letter_storage_id          = string
    dead_letter_container_name      = string
    topic_principal_id              = optional(string)
    handler_acceptance_reference    = string
    handler_updates_backing_service = bool
    event_delivery_network_ready    = bool
  }))
  default = {}
  validation {
    condition = alltrue([for item in values(var.secret_rotations) :
      length(item.secret_names) > 0 && item.handler_updates_backing_service &&
      (item.create_system_topic || item.topic_principal_id != null) &&
      item.event_delivery_network_ready && length(trimspace(item.handler_acceptance_reference)) > 0 &&
      can(regex("(?i)/providers/Microsoft.KeyVault/vaults/[^/]+$", item.vault_id)) &&
      can(regex("(?i)/providers/Microsoft.Web/sites/[^/]+/functions/[^/]+$", item.function_id)) &&
      alltrue([for name in item.secret_names : can(regex("^[0-9a-zA-Z-]+$", name))])
    ])
    error_message = "Rotation needs named secrets, a tested idempotent handler that updates the backing service, valid vault/function IDs and confirmed Event Grid network delivery."
  }
  validation {
    condition     = length(distinct([for item in values(var.secret_rotations) : lower(item.vault_id)])) == length(var.secret_rotations)
    error_message = "Use one rotation entry per vault; include all approved secret names to avoid competing subscriptions."
  }
}
