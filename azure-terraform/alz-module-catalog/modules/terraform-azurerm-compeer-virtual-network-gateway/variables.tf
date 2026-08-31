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
variable "type" {
  type    = string
  default = "ExpressRoute"
}
variable "vpn_type" {
  type    = string
  default = "RouteBased"
}
variable "sku" {
  type    = string
  default = "ErGw1AZ"
}
variable "active_active" {
  type    = bool
  default = false
}
variable "enable_bgp" {
  type    = bool
  default = true
}
variable "generation" {
  type    = string
  default = null
}
variable "ip_configurations" {
  type = map(object({
    public_ip_address_id          = string
    subnet_id                     = string
    private_ip_address_allocation = optional(string, "Dynamic")
  }))
}
variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
