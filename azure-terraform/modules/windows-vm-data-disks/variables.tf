variable "name_prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "virtual_machine_id" { type = string }
variable "zone" {
  type    = string
  default = null
}
variable "disks" {
  type = map(object({
    name                      = optional(string)
    lun                       = number
    disk_size_gb              = number
    storage_account_type      = string
    caching                   = string
    create_option             = optional(string, "Empty")
    zone                      = optional(string)
    disk_encryption_set_id    = optional(string)
    write_accelerator_enabled = optional(bool)
    tags                      = optional(map(string), {})
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
