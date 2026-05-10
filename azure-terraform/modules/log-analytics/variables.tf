variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "sku" {
  type    = string
  default = "PerGB2018"
}
variable "retention_in_days" {
  type    = number
  default = 30
}
variable "daily_quota_gb" {
  type    = number
  default = null
}
variable "internet_ingestion_enabled" {
  type    = bool
  default = true
}
variable "internet_query_enabled" {
  type    = bool
  default = true
}
variable "reservation_capacity_in_gb_per_day" {
  type    = number
  default = null
}
variable "cmk_for_query_forced" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
