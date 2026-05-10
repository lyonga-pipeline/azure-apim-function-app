variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tenant_id" { type = string }
variable "sku_name" {
  type    = string
  default = "standard"
}
variable "soft_delete_retention_days" {
  type    = number
  default = 90
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}
variable "purge_protection_enabled" {
  type    = bool
  default = true
}
variable "enable_rbac_authorization" {
  type    = bool
  default = true
}
variable "public_network_access_enabled" {
  type    = bool
  default = false
}
variable "network_acls" {
  type = object({
    bypass                     = optional(string, "None")
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = {}
}
variable "contacts" {
  type = map(object({
    email = string
    name  = optional(string)
    phone = optional(string)
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
