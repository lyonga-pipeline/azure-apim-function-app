locals {
  is_production       = var.environment == "prod"
  resource_group_keys = concat(["network", "security", "application", "operations"], length(var.storage_accounts) > 0 ? ["data"] : [])
  environment_profile = {
    tier                          = local.is_production ? "production" : "non-production"
    storage_replication_type      = local.is_production ? "ZRS" : "LRS"
    blob_delete_retention_days    = local.is_production ? 30 : 7
    telemetry_sampling_percentage = coalesce(var.monitoring.sampling_percentage, local.is_production ? 100 : 20)
    alert_severity                = local.is_production ? 1 : 3
    alert_frequency               = local.is_production ? "PT1M" : "PT5M"
    failed_request_threshold      = coalesce(var.monitoring.failed_request_threshold, local.is_production ? 5 : 20)
    recovery_ownership            = "application-team-approved-backup-policy"
  }
  storage_replication = { for key, account in var.storage_accounts : key => coalesce(account.replication_type, local.environment_profile.storage_replication_type) }
  storage_retention   = { for key, account in var.storage_accounts : key => coalesce(account.delete_retention_days, local.environment_profile.blob_delete_retention_days) }
}

variable "operations" {
  description = "Approved workload alert destinations and subscription budget. Existing central action groups may be reused; no dead-end action group is created."
  type = object({
    notification_emails = optional(set(string), [])
    action_group_ids    = optional(set(string), [])
    budget = object({
      amount     = number
      start_date = string
    })
  })
  validation {
    condition = (
      length(var.operations.notification_emails) + length(var.operations.action_group_ids) > 0 &&
      alltrue([for email in var.operations.notification_emails : can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", email)) && !strcontains(lower(email), "replace")]) &&
      alltrue([for id in var.operations.action_group_ids : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Insights/actionGroups/[^/]+$", id))])
    )
    error_message = "Provide approved, real notification emails and/or existing action-group ARM IDs; placeholders cannot receive operational alerts."
  }
  validation {
    condition     = var.operations.budget.amount > 0 && can(regex("^[0-9]{4}-[0-9]{2}-01T00:00:00Z$", var.operations.budget.start_date)) && can(formatdate("YYYY-MM-DD", var.operations.budget.start_date))
    error_message = "Set an approved positive monthly budget in the billing currency and a stable first-of-month UTC start_date. Budgets notify; they do not cap spending."
  }
}

variable "monitoring" {
  description = "Workspace-based application telemetry. Tune sampling/failure thresholds to the actual SLO; private-only endpoints require the separately owned Azure Monitor Private Link path."
  type = object({
    sampling_percentage        = optional(number)
    failed_request_threshold   = optional(number)
    internet_ingestion_enabled = optional(bool, true)
    internet_query_enabled     = optional(bool, true)
    private_link_ready         = optional(bool, false)
  })
  default = {}
  validation {
    condition = (
      (var.monitoring.sampling_percentage == null ? true : var.monitoring.sampling_percentage > 0 && var.monitoring.sampling_percentage <= 100) &&
      (var.monitoring.failed_request_threshold == null ? true : var.monitoring.failed_request_threshold > 0) &&
      ((var.monitoring.internet_ingestion_enabled && var.monitoring.internet_query_enabled) || var.monitoring.private_link_ready)
    )
    error_message = "Use valid sampling/thresholds. Disabling public telemetry ingestion/query requires an approved, already working central Azure Monitor Private Link/DNS path."
  }
}

variable "storage_accounts" {
  description = "Optional, actually consumed private Blob stores. No unused account is deployed by default. Azure Files/queues/ADLS need separate service-specific extensions."
  type = map(object({
    name                       = optional(string)
    replication_type           = optional(string)
    delete_retention_days      = optional(number)
    grant_workload_blob_access = optional(bool, false)
  }))
  default = {}
  validation {
    condition = alltrue([for account in values(var.storage_accounts) :
      (account.replication_type == null ? true : contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], account.replication_type)) &&
      (account.delete_retention_days == null ? true : account.delete_retention_days >= 7 && account.delete_retention_days <= 365 && floor(account.delete_retention_days) == account.delete_retention_days)
    ])
    error_message = "Storage uses approved replication types and 7-365 whole days of delete retention; production applies stronger additional checks."
  }
}

variable "backup" {
  description = "Optional VM backup registration into an existing workload-subscription vault/policy. Compute and the vault/policy lifecycle remain with their approved owners."
  type = object({
    recovery_vault_id = string
    backup_policy_id  = string
    virtual_machines  = map(string)
  })
  default = null
  validation {
    condition = var.backup == null ? true : (
      length(var.backup.virtual_machines) > 0 &&
      can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.RecoveryServices/vaults/[^/]+$", var.backup.recovery_vault_id)) &&
      startswith(lower(var.backup.backup_policy_id), "${lower(var.backup.recovery_vault_id)}/backuppolicies/") &&
      alltrue([for id in values(var.backup.virtual_machines) : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Compute/virtualMachines/[^/]+$", id))])
    )
    error_message = "Backup requires existing VM IDs, a Recovery Services vault ID and an approved policy belonging to that vault. Empty/unattached vaults are not deployed."
  }
}

resource "terraform_data" "capability_contract" {
  lifecycle {
    precondition {
      condition = length(var.storage_accounts) == 0 || (
        can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/privateDnsZones/privatelink\\.blob\\.core\\.windows\\.net$", var.platform.storage_blob_private_dns_zone_id)) &&
        try(lower(split("/", var.platform.storage_blob_private_dns_zone_id)[2]) == lower(data.azurerm_client_config.dns.subscription_id), false)
      )
      error_message = "Private Blob storage requires the actual existing central Blob DNS-zone ID and its correct DNS provider subscription."
    }
    precondition {
      condition = !local.is_production || alltrue([for key in keys(var.storage_accounts) :
        contains(["ZRS", "GZRS", "RAGZRS"], local.storage_replication[key]) && local.storage_retention[key] >= 30
      ])
      error_message = "This production profile requires zone-redundant storage and at least 30 days of Blob/container delete retention. Region/DR exceptions need a separately reviewed profile."
    }
    precondition {
      condition = var.backup == null ? true : (
        try(lower(split("/", var.backup.recovery_vault_id)[2]) == lower(var.subscription_id), false) &&
        alltrue([for id in values(var.backup.virtual_machines) : try(lower(split("/", id)[2]) == lower(var.subscription_id), false)])
      )
      error_message = "VMs and their Recovery Services vault must belong to this workload subscription. Cross-subscription backup is not assumed."
    }
  }
}
