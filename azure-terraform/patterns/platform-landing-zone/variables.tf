variable "implementation_overrides" {
  type = map(object({
    status         = optional(string)
    workspace      = optional(string)
    pattern        = optional(string)
    implementation = optional(string)
    cost_state     = optional(string)
    notes          = optional(string)
  }))
  description = "Optional overrides for the platform component coverage contract. Keys must match component IDs such as GOV-01 or NET-18."
  default     = {}

  validation {
    condition = alltrue([
      for item in values(var.implementation_overrides) :
      try(item.status, null) == null ? true : contains([
        "implemented",
        "contract",
        "external-governed",
        "cost-disabled",
        "advisory",
        "module-only",
        "not-composed",
        "documentation"
      ], item.status)
    ])
    error_message = "implementation_overrides[*].status must be implemented, contract, external-governed, cost-disabled, advisory, module-only, not-composed, or documentation."
  }
}
