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
variable "sku" {
  type    = string
  default = "Standard"
}
variable "threat_intelligence_mode" {
  type    = string
  default = "Alert"
}
variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
