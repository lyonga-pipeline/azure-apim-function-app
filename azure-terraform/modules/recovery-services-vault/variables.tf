variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
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
variable "tags" {
  type    = map(string)
  default = {}
}
