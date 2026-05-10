variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "os_type" {
  type    = string
  default = "Windows"
  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "os_type must be Linux or Windows."
  }
}
variable "sku_name" { type = string }
variable "worker_count" {
  type    = number
  default = null
}
variable "maximum_elastic_worker_count" {
  type    = number
  default = null
}
variable "per_site_scaling_enabled" {
  type    = bool
  default = false
}
variable "zone_balancing_enabled" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
