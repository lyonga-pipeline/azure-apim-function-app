variable "name" {
  description = "Resource name. Changing this forces a new resource."
  type        = string
}
variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string
}
variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}
variable "sku" {
  type    = string
  default = "Standard"
}
variable "soft_delete_enabled" {
  type    = bool
  default = true
}
variable "storage_mode_type" {
  type    = string
  default = "GeoRedundant"
}
variable "public_network_access_enabled" {
  type    = bool
  default = null
}
variable "immutability" {
  type    = string
  default = null
}
variable "cross_region_restore_enabled" {
  type    = bool
  default = null
}
variable "classic_vmware_replication_enabled" {
  type    = bool
  default = null
}
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}
variable "encryption" {
  type = object({
    key_id                            = string
    infrastructure_encryption_enabled = optional(bool)
    use_system_assigned_identity      = optional(bool)
    user_assigned_identity_id         = optional(string)
  })
  default = null
}
variable "monitoring" {
  type = object({
    alerts_for_all_job_failures_enabled            = optional(bool)
    alerts_for_all_failover_issues_enabled         = optional(bool)
    alerts_for_all_replication_issues_enabled      = optional(bool)
    alerts_for_critical_operation_failures_enabled = optional(bool)
    email_notifications_for_site_recovery_enabled  = optional(bool)
  })
  default = null
}
variable "timeouts" {
  type = object({
    create = optional(string)
    update = optional(string)
    read   = optional(string)
    delete = optional(string)
  })
  default = {}
}
variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
