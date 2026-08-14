variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "service_provider_name" {
  type = string
}
variable "peering_location" {
  type = string
}
variable "bandwidth_in_mbps" {
  type = number
}
variable "allow_classic_operations" {
  type    = bool
  default = false
}
variable "sku" {
  type = object({
    tier   = string
    family = string
  })
  default = {
    tier   = "Standard"
    family = "MeteredData"
  }
}
variable "tags" {
  type    = map(string)
  default = {}
}
