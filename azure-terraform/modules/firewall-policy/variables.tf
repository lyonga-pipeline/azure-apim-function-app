variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "sku" {
  type    = string
  default = "Standard"
}
variable "threat_intelligence_mode" {
  type    = string
  default = "Alert"
}
variable "tags" {
  type    = map(string)
  default = {}
}
