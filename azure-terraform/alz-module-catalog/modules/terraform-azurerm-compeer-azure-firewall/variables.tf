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
variable "sku_name" {
  type    = string
  default = "AZFW_VNet"
}
variable "sku_tier" {
  type    = string
  default = "Standard"
}
variable "firewall_policy_id" {
  type    = string
  default = null
}
variable "ip_configurations" {
  type = map(object({
    subnet_id            = optional(string)
    public_ip_address_id = string
  }))
}
variable "zones" {
  type    = list(string)
  default = []
}
variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
