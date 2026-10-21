variable "allow_live_deployment" {
  description = "Explicit cost/deployment approval for an isolated Azure test subscription. Never enable in production."
  type        = bool
  default     = false
}
variable "test_subscription_id" {
  description = "Explicit isolated test subscription UUID, never inferred from the current Azure CLI context."
  type        = string
}
variable "run_id" {
  description = "Unique approved test run ID; do not reuse while a purge-protected test vault is soft-deleted."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.run_id))
    error_message = "run_id must contain 3-24 alphanumeric/hyphen characters."
  }
}
variable "cost_center" {
  description = "Real test cost center; no client production value is assumed."
  type        = string
}
variable "location" {
  type    = string
  default = "centralus"
}
variable "created_on" {
  description = "Stable test-run date in YYYY-MM-DD format."
  type        = string
}
variable "notification_email" {
  description = "Approved test notification recipient; never invent a client distribution list."
  type        = string
  default     = null
}
variable "enable_optional_operations_test" {
  description = "Explicit opt-in to test approved Phase 2 telemetry/alerts; false exercises the Phase 1 foundation."
  type        = bool
  default     = false
}
variable "enable_blob_storage_test" {
  description = "Exercise the optional private Blob capability and its observed control-plane recovery/diagnostic settings."
  type        = bool
  default     = true
}
variable "enable_vault_test" {
  description = "False exercises the approved secretless-spoke variant; vault DNS/secret probes must also be disabled."
  type        = bool
  default     = true
}
variable "private_endpoint_client_cidrs" {
  description = "Approved CIDRs of the network-connected test runner; peering and DNS access must be arranged before the private data-plane probe."
  type        = list(string)
  default     = []
}
variable "enable_secret_probe_operator" {
  description = "Opt-in temporary vault-scoped Secrets Officer for the test run identity, only for the isolated secret round-trip test."
  type        = bool
  default     = false
}
variable "runner_principal_type" {
  type    = string
  default = "ServicePrincipal"
  validation {
    condition     = contains(["ServicePrincipal", "User"], var.runner_principal_type)
    error_message = "The Azure test-run identity must be a service principal or explicitly approved user."
  }
}
