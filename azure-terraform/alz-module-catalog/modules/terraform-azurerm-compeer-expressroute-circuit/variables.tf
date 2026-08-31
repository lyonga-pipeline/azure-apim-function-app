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
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
