variable "resource_group_name" {
  description = "Existing workload resource group; this pattern does not create or move resource groups."
  type        = string
}

variable "location" {
  description = "Azure deployment region; naming resolves the approved short code."
  type        = string
}

variable "tenant_id" {
  description = "Entra tenant containing the vault and its principals."
  type        = string
}

variable "environment" {
  description = "Approved workload environment."
  type        = string
}

variable "appcode" {
  description = "Approved application code, shared with the spoke naming and tags."
  type        = string
}

variable "domain" {
  description = "Workload domain used by the naming module."
  type        = string
  default     = "internal-apps"
}

variable "name" {
  description = "Optional approved globally unique vault name; null uses the naming module."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "Standard unless a documented HSM-backed key requirement justifies premium."
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "private_endpoint_subnet_id" {
  description = "Existing non-delegated workload private endpoint subnet, with NSG policies enabled."
  type        = string
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.private_endpoint_subnet_id))
    error_message = "private_endpoint_subnet_id must be a full Azure subnet resource ID."
  }
}

variable "private_dns_zone_id" {
  description = "Existing centrally owned privatelink.vaultcore.azure.net zone; never create a duplicate zone here."
  type        = string
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/privateDnsZones/privatelink\\.vaultcore\\.azure\\.net$", var.private_dns_zone_id))
    error_message = "private_dns_zone_id must identify the approved privatelink.vaultcore.azure.net zone."
  }
}

variable "log_analytics_workspace_id" {
  description = "Central platform LAW resource ID, not the workspace GUID."
  type        = string
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$", var.log_analytics_workspace_id))
    error_message = "log_analytics_workspace_id must be a full workspace resource ID."
  }
}

variable "secret_readers" {
  description = "Stable logical keys mapped to approved workload identity/group object IDs. Vault-scoped Secrets User only."
  type = map(object({
    principal_id   = string
    principal_type = optional(string, "ServicePrincipal")
  }))
  default = {}
  validation {
    condition = alltrue([for reader in values(var.secret_readers) :
      can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", reader.principal_id)) &&
      reader.principal_id != "00000000-0000-0000-0000-000000000000" &&
      contains(["ServicePrincipal", "Group"], reader.principal_type)
    ])
    error_message = "Readers must use real Entra object IDs and ServicePrincipal or Group principal types, not application/client IDs or individual users."
  }
}

variable "secret_officer_group_ids" {
  description = "Explicitly approved security/operator group object IDs. No deployment identity is granted secret access automatically."
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([for id in values(var.secret_officer_group_ids) :
      can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", id)) && id != "00000000-0000-0000-0000-000000000000"
    ])
    error_message = "Secret officers must be approved groups with real Entra object IDs."
  }
}

variable "tags" {
  description = "Output of the shared tags module, including the root-owned stable created_on date."
  type        = map(string)
  validation {
    condition = alltrue([for key in ["environment", "application", "appcode", "owner", "source_repo", "created_on", "criticality_tier", "data_classification", "lifecycle_state", "cost_center", "gl_category", "created_by"] :
      try(length(trimspace(var.tags[key])) > 0, false)
    ])
    error_message = "Use the shared tags module to supply all mandatory ownership, classification, cost and creation tags."
  }
}
