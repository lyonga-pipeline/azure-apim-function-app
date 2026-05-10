variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "application_type" {
  type    = string
  default = "web"
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
}
variable "sampling_percentage" {
  type    = number
  default = null
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
