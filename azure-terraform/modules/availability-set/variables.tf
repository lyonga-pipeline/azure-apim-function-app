variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "platform_fault_domain_count" {
  type    = number
  default = 2
}
variable "platform_update_domain_count" {
  type    = number
  default = 5
}
variable "proximity_placement_group_id" {
  type    = string
  default = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
