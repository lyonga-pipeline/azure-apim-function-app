variable "resource_group_name" { type = string }
variable "location" {
  type    = string
  default = "centralus"
}
variable "tags" {
  type    = map(string)
  default = {}
}
# PHASE2 NEW: v5 2.3 OBS-05. No invented regulatory retention or automatic irreversible lock.
variable "archive" {
  type = object({
    name                         = string
    workspace_id                 = string
    workspace_region             = string
    audit_workspace_id           = string
    private_endpoint_subnet_id   = string
    private_dns_zone_id          = string
    retention_days               = number
    retention_approval_reference = string
    lock_immutability            = optional(bool, false)
    irreversible_lock_approved   = optional(bool, false)
    export_access_approved       = bool
    replication_type             = optional(string, "ZRS")
    tables                       = set(string)
    delete_after_days            = optional(number)
  })
  default = null
  validation {
    condition = var.archive == null ? true : (
      var.archive.retention_days >= 1 && var.archive.retention_days <= 146000 &&
      floor(var.archive.retention_days) == var.archive.retention_days &&
      length(trimspace(var.archive.retention_approval_reference)) > 0 &&
      (!var.archive.lock_immutability || var.archive.irreversible_lock_approved) &&
      var.archive.export_access_approved && length(var.archive.tables) > 0 &&
      (lower(var.archive.audit_workspace_id) != lower(var.archive.workspace_id) || length(setintersection(toset([for table in var.archive.tables : lower(table)]), toset(["storagebloblogs", "azuremetrics"]))) == 0) &&
      contains(["ZRS", "GZRS", "RAGZRS"], var.archive.replication_type) &&
      (var.archive.delete_after_days == null ? true : var.archive.delete_after_days > var.archive.retention_days)
    )
    error_message = "Archive needs approved retention/export access, resilient replication and tables. Same-LAW audit reuse cannot export StorageBlobLogs/AzureMetrics back to this account. Locking requires separate approval; deletion must follow retention."
  }
}
