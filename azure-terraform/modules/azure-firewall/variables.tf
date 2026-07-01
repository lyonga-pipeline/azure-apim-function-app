variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
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
  type    = map(string)
  default = {}
}
