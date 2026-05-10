variable "storage_container_resource_manager_id" { type = string }
variable "immutability_period_in_days" { type = number }
variable "locked" {
  type    = bool
  default = false
}
variable "protected_append_writes_enabled" {
  type    = bool
  default = false
}
variable "protected_append_writes_all_enabled" {
  type    = bool
  default = false
}
variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
