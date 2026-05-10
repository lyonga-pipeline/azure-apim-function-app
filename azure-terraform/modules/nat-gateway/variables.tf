variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "sku_name" {
  type    = string
  default = "Standard"
}
variable "idle_timeout_in_minutes" {
  type    = number
  default = 10
}
variable "zones" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
