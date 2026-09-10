variable "contracts" {
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
  default     = {}
  description = <<-EOT
    Non-resource ALZ operational controls that are tracked here rather than
    provisioned. Each key is a control; implementation_state records why it is
    not (or not yet) Terraform-managed:
      - codified       : the control IS created by Terraform elsewhere; this entry
                         is a cross-reference only.
      - manual-control : deliberately outside Terraform (break-glass, tenant
                         lockout risk) - see notes for the rationale.
      - external-system: owned by an IGA / ITSM / SOC system, not IaC.
      - provider-gap   : would be IaC but the provider lacks coverage today.
      - contract-only  : agreed but not yet implemented anywhere (may not be enabled).
  EOT

  validation {
    condition = alltrue([
      for c in values(var.contracts) : contains(
        ["codified", "manual-control", "external-system", "provider-gap", "contract-only"],
        c.implementation_state
      )
    ])
    error_message = "implementation_state must be one of: codified, manual-control, external-system, provider-gap, contract-only."
  }
}
