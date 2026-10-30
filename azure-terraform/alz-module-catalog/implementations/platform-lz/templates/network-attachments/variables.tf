variable "environment" {
  description = "Approved boundary label committed for this copied root; never choose another environment at runtime."
  type        = string
}

variable "enabled" {
  description = "Explicit adoption gate. false is inert for an UNAPPLIED root, not a safe way to suspend a deployed attachment state."
  type        = bool
  default     = false
}
variable "tenant_id" {
  type        = string
  description = "Approved Entra tenant UUID."
}
variable "execution_subscription_id" {
  type        = string
  description = "Provider context only; child resources are addressed by full hub/spoke/zone IDs."
}
variable "hub" {
  description = "Approved shared hub and public connectivity producer."
  type = object({
    virtual_network_id = string
    address_space      = set(string)
    organization       = string
    workspace          = string
    contract_version   = optional(string, "0.1.0")
    gateway_ready      = optional(bool, false)
  })
  default = null
}
variable "reserved_address_spaces" {
  type        = set(string)
  description = "Complete external IPAM inventory excluding the hub and this batch."
  default     = []
}
variable "attachments" {
  description = "Network-approved Git inventory. Stable keys are resource identities; removal is an approved teardown."
  type = map(object({
    attachment_kind          = optional(string, "workload")
    spoke_virtual_network_id = string
    address_space            = set(string)
    producer = object({
      organization     = string
      workspace        = string
      contract_version = optional(string, "2.0.0")
    })
    naming_context          = optional(object({ region = string, environment = string, domain = string, appcode = string }))
    approval_reference      = string
    ipam_reference          = string
    gateway_transit         = optional(bool, false)
    allow_forwarded_traffic = optional(bool, true)
    private_dns_zone_ids    = optional(map(string), {})
    peering_names           = optional(object({ hub_to_spoke = string, spoke_to_hub = string }))
    private_dns_link_names  = optional(map(string), {})
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "deployment_controls" {
  description = "Recorded adoption approvals; these attestations do not configure or replace the protected pipeline gate."
  type = object({
    approval_reference           = string
    exclusive_ownership_verified = bool
    shared_hub_gate_configured   = bool
  })
  default = { approval_reference = "", exclusive_ownership_verified = false, shared_hub_gate_configured = false }
}
variable "allow_local_cli_auth" {
  description = "Explicit local test exception; keep false in HCP."
  type        = bool
  default     = false
}
variable "tfc_azure_dynamic_credentials" {
  description = "Credential file paths injected by HCP; never populate with tokens in tfvars."
  type = object({
    default = object({ client_id_file_path = string, oidc_token_file_path = string })
    aliases = map(object({ client_id_file_path = string, oidc_token_file_path = string }))
  })
  default = null
}
