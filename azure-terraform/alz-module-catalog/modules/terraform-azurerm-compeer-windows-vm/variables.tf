variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}
variable "network_interface_ids" {
  type = list(string)
}
variable "admin_username" {
  type    = string
  default = "azureadmin"
}
variable "admin_password" {
  type      = string
  sensitive = true
  validation {
    condition = (
      length(var.admin_password) >= 14 &&
      can(regex("[A-Z]", var.admin_password)) &&
      can(regex("[a-z]", var.admin_password)) &&
      can(regex("[0-9]", var.admin_password)) &&
      can(regex("[^A-Za-z0-9]", var.admin_password))
    )
    error_message = "admin_password must be at least 14 characters and include upper, lower, number, and special characters."
  }
}
variable "computer_name" {
  type    = string
  default = null
}
variable "availability_set_id" {
  type    = string
  default = null
}
variable "zone" {
  type    = string
  default = null
}
variable "source_image_id" {
  type    = string
  default = null
}
variable "source_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = null
}
variable "plan" {
  type = object({
    name      = string
    publisher = string
    product   = string
  })
  default = null
}
variable "license_type" {
  type    = string
  default = "Windows_Server"
}
variable "timezone" {
  type    = string
  default = "UTC"
}
variable "provision_vm_agent" {
  type    = bool
  default = true
}
variable "allow_extension_operations" {
  type    = bool
  default = true
}
variable "enable_automatic_updates" {
  type    = bool
  default = true
}
variable "patch_mode" {
  type    = string
  default = "AutomaticByPlatform"
}
variable "patch_assessment_mode" {
  type    = string
  default = "AutomaticByPlatform"
}
variable "hotpatching_enabled" {
  type    = bool
  default = false
}
variable "secure_boot_enabled" {
  type    = bool
  default = true
}
variable "vtpm_enabled" {
  type    = bool
  default = true
}
variable "encryption_at_host_enabled" {
  type    = bool
  default = true
}
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}
variable "boot_diagnostics" {
  type = object({
    storage_account_uri = optional(string)
  })
  default = null
}
variable "additional_capabilities" {
  type = object({
    ultra_ssd_enabled = optional(bool, false)
  })
  default = null
}
variable "os_disk" {
  type = object({
    caching                   = string
    storage_account_type      = string
    disk_size_gb              = optional(number)
    name                      = optional(string)
    write_accelerator_enabled = optional(bool)
    disk_encryption_set_id    = optional(string)
  })
  default = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
}
variable "tags" {
  type    = map(string)
  default = {}
}
