variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "application_type" {
  type    = string
  default = "web"

  validation {
    condition     = contains(["ios", "java", "MobileCenter", "Node.JS", "other", "phone", "store", "web"], var.application_type)
    error_message = "application_type must be one of ios, java, MobileCenter, Node.JS, other, phone, store, or web."
  }
}
variable "workspace_id" {
  type    = string
  default = null
}
variable "daily_data_cap_in_gb" {
  type    = number
  default = null
}
variable "daily_data_cap_notifications_disabled" {
  type    = bool
  default = false
}
variable "retention_in_days" {
  type    = number
  default = 90

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days must be between 30 and 730."
  }
}
variable "sampling_percentage" {
  type    = number
  default = null

  validation {
    condition     = var.sampling_percentage == null || (var.sampling_percentage >= 0 && var.sampling_percentage <= 100)
    error_message = "sampling_percentage must be between 0 and 100 when set."
  }
}
variable "disable_ip_masking" {
  type    = bool
  default = false
}
variable "local_authentication_disabled" {
  type    = bool
  default = true
}
variable "internet_ingestion_enabled" {
  type    = bool
  default = true
}
variable "internet_query_enabled" {
  type    = bool
  default = true
}
variable "force_customer_storage_for_profiler" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
