variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tenant_id" { type = string }
variable "sku_name" {
  type    = string
  default = "Standard_B1"
}
variable "purge_protection_enabled" {
  type    = bool
  default = true
}
variable "soft_delete_retention_days" {
  type    = number
  default = 90
}
variable "public_network_access_enabled" {
  type    = bool
  default = false
}
variable "admin_object_ids" {
  type = list(string)
}
variable "network_acls" {
  type = object({
    bypass         = optional(string, "None")
    default_action = optional(string, "Deny")
  })
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
