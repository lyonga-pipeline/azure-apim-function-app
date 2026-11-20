variable "environment" {
  type = string
  validation {
    condition     = contains(["prod", "nonprod"], var.environment)
    error_message = "Deploy independent prod and nonprod workspaces, identities and state."
  }
}
variable "location" { type = string }
variable "tenant_id" { type = string }
variable "resource_group_name" { type = string }
variable "names" {
  type = object({ worker = string, scheduler = string, plan = string, host_storage = string, state_storage = string, service_bus = string })
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "integration_subnet_id" {
  description = "Existing subnet delegated to Microsoft.Web/serverFarms; separate from the private endpoint subnet."
  type        = string
}
variable "private_endpoint_subnet_id" { type = string }
variable "private_dns_zone_ids" {
  description = "Existing blob, queue, table, servicebus, sites zones. Omit entries only when central policy owns their zone groups."
  type        = map(string)
  default     = {}
}
variable "dns_owned_by_policy" {
  type    = bool
  default = false
}
variable "log_analytics_workspace_id" { type = string }
variable "action_group_ids" {
  type = list(string)
  validation {
    condition     = length(var.action_group_ids) > 0
    error_message = "At least one approved Operations/SOC action group is required."
  }
}
variable "manual_api_client_id" {
  description = "Existing Entra API application client ID with api://client-id audience. No client secret is used."
  type        = string
}
variable "operator_group_ids" {
  description = "Approved Entra operator groups allowed through Function App Easy Auth. Request-level object IDs are checked separately."
  type        = list(string)
  validation {
    condition     = length(var.operator_group_ids) > 0
    error_message = "Manual API must be restricted to approved operator groups."
  }
}
variable "event_delivery_exception_approved" {
  description = "Explicit approval for Event Grid MI delivery using Service Bus and state-storage trusted-service exceptions. False supports scheduler/manual only."
  type        = bool
  default     = false
}
variable "package_path" {
  description = "Built Linux Python 3.12 Functions ZIP with dependencies; deploy from a private-network runner. Null provisions infrastructure only."
  type        = string
  default     = null
}
variable "consumer_hosts" {
  description = "Reviewed HTTPS refresh/validation adapter hosts. No URL queries, embedded credentials or redirects allowed."
  type        = set(string)
}
variable "vaults" {
  description = "Explicit allowlist of workload vault scopes; no automatic trust from a tag alone. Vault owner manages PE/DNS and enrollment module."
  type        = map(object({ id = string, url = string }))
  default     = {}
}
variable "assets" {
  description = "Nonsecret approved registry. Never put credential values in Terraform. See README for bootstrap metadata and consumer evidence contract."
  type = map(object({
    enabled                     = optional(bool, false)
    environment                 = string
    vault_id                    = string
    vault_url                   = string
    secret_name                 = string
    adapter                     = string
    target                      = map(string)
    owner                       = string
    support_group               = string
    approval_reference          = string
    recovery_reference          = string
    adapter_approved            = bool
    consumer_inventory_reviewed = bool
    initial_due                 = string
    interval_days               = optional(number, 90)
    credential_lifetime_days    = optional(number, 120)
    overlap_hours               = optional(number, 24)
    minimum_overlap_minutes     = optional(number, 15)
    exception_until             = optional(string)
    consumers                   = list(object({ name = string, refresh_url = string, validate_url = string, audience = string }))
  }))
  default = {}
  validation {
    condition = alltrue([for key, asset in var.assets :
      can(regex("^[a-z0-9-]{1,64}$", key)) &&
      contains(["storage_dual_key", "entra_application"], asset.adapter) &&
      can(formatdate("YYYY", asset.initial_due)) && asset.interval_days >= 1 &&
      asset.credential_lifetime_days > asset.interval_days && asset.overlap_hours > 0 &&
      asset.overlap_hours <= 24 && asset.minimum_overlap_minutes >= 0 &&
      asset.minimum_overlap_minutes < asset.overlap_hours * 60 &&
      can(regex("^[a-zA-Z0-9-]{1,127}$", asset.secret_name)) &&
      length(asset.consumers) > 0 &&
      (asset.adapter == "storage_dual_key" ? can(regex("(?i)^/subscriptions/[0-9a-f-]+/resourceGroups/[^/]+/providers/Microsoft.Storage/storageAccounts/[a-z0-9]+$", asset.target["resource_id"])) :
      can(regex("^[0-9a-fA-F-]{36}$", asset.target["resource_id"])))
    ])
    error_message = "Assets require stable keys, supported authority IDs, valid dates, consumers, safe interval/overlap limits and a credential lifetime beyond the rotation interval."
  }
  validation {
    condition     = length(distinct([for a in values(var.assets) : "${lower(a.vault_id)}:${lower(a.secret_name)}"])) == length(var.assets)
    error_message = "Only one registered asset may own each vault secret."
  }
}
variable "manual_approvals" {
  description = "Reviewed, expiring single-cycle authorizations. Request ID is the map key; changing approval references is an IaC approval, not free text from an HTTP caller."
  type = map(object({
    asset_id                 = string
    mode                     = string
    approval_reference       = string
    expires_at               = string
    operator_object_ids      = set(string)
    clean_identity_confirmed = optional(bool, false)
  }))
  default = {}
  validation {
    condition = alltrue([for key, approval in var.manual_approvals :
      can(regex("^[a-zA-Z0-9-]{1,64}$", key)) &&
      contains(["manual", "emergency"], approval.mode) &&
      length(trimspace(approval.approval_reference)) > 0 && length(approval.operator_object_ids) > 0 &&
      can(formatdate("YYYY", approval.expires_at))
    ])
    error_message = "Manual/emergency approvals require bounded request IDs, a change/incident reference, expiry and named operator object IDs."
  }
}
