variable "workload_identities" {
  description = <<-EOT
    Federated (secret-less) workload identities for CI/CD and IaC automation —
    design doc Phase 4 Step 7-8. Each entry is one Entra app registration + its
    service principal, plus federated credentials (OIDC trust rules) and the
    Azure roles the SP holds.

    federated_credentials: one per plan/apply run phase per workspace.
      issuer  — e.g. "https://app.terraform.io" (HCP), "https://token.actions.githubusercontent.com" (GitHub),
                "https://vstoken.dev.azure.com/<org-id>" (Azure DevOps).
      subject — the exact token subject, e.g.
                "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-governance:run_phase:apply".
      NOTE: an app registration has a hard limit of 20 federated credentials.

    azure_role_assignments: SP -> built-in role -> scope (full resource ID).
  EOT
  type = map(object({
    display_name            = string
    description             = optional(string)
    owners                  = optional(list(string), [])
    tags                    = optional(list(string), ["terraform", "landing-zone"])
    notes                   = optional(string)
    sign_in_audience        = optional(string, "AzureADMyOrg")
    prevent_duplicate_names = optional(bool, true)

    federated_credentials = optional(map(object({
      display_name = string
      description  = optional(string)
      issuer       = string
      subject      = string
      audiences    = optional(list(string), ["api://AzureADTokenExchange"])
    })), {})

    azure_role_assignments = optional(map(object({
      scope                = string
      role_definition_name = string
      description          = optional(string)
      condition            = optional(string)
      condition_version    = optional(string)
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for wi in values(var.workload_identities) : length(wi.federated_credentials) <= 20
    ])
    error_message = "An app registration supports at most 20 federated credentials; split repeating workspaces across more identities or use flexible FICs."
  }
}

variable "operational_contracts" {
  description = "Workload-identity controls not provisioned here (HCP variable-set wiring, GitHub/ADO service-connection config, credential-rotation attestation)."
  type = map(object({
    phase                = optional(string, "Phase 4")
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
