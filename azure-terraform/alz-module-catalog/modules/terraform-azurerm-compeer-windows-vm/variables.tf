variable "name" {
  description = "VM name. Changing this forces a new resource."
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
variable "vm_size" {
  description = "VM SKU size."
  type        = string
  default     = "Standard_D2s_v5"
}
variable "network_interface_ids" {
  description = "NIC resource IDs to attach. First is primary. NICs are caller-owned."
  type        = list(string)
}
variable "admin_username" {
  description = "Local administrator username."
  type        = string
  default     = "azureadmin"
}
variable "admin_password" {
  description = "Local administrator password. Stored in state - protect the backend."
  type        = string
  sensitive   = true
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
  description = "Windows computer name (<=15 chars). Defaults to a sanitised prefix of name."
  type        = string
  default     = null
}
variable "availability_set_id" {
  description = "Availability set to place the VM in. Mutually exclusive with zone."
  type        = string
  default     = null
}
variable "zone" {
  description = "Availability zone. Mutually exclusive with availability_set_id. Changing this forces a new resource."
  type        = string
  default     = null
}
variable "source_image_id" {
  description = "Managed image / shared image ID. Mutually exclusive with source_image_reference."
  type        = string
  default     = null
}
variable "source_image_reference" {
  description = "Marketplace image reference. Mutually exclusive with source_image_id."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = null
}
variable "plan" {
  description = "Marketplace plan for images that require one."
  type = object({
    name      = string
    publisher = string
    product   = string
  })
  default = null
}
variable "license_type" {
  description = "Windows_Server, Windows_Client, or None (hybrid benefit)."
  type        = string
  default     = "Windows_Server"
}
variable "timezone" {
  description = "VM timezone."
  type        = string
  default     = "UTC"
}
variable "provision_vm_agent" {
  description = "Install the Azure VM agent."
  type        = bool
  default     = true
}
variable "allow_extension_operations" {
  description = "Allow VM extension operations."
  type        = bool
  default     = true
}
variable "automatic_updates_enabled" {
  description = "Enable Windows automatic updates."
  type        = bool
  default     = true
}
variable "patch_mode" {
  description = "Manual, AutomaticByOS, or AutomaticByPlatform."
  type        = string
  default     = "AutomaticByPlatform"

  validation {
    condition     = contains(["Manual", "AutomaticByOS", "AutomaticByPlatform"], var.patch_mode)
    error_message = "patch_mode must be Manual, AutomaticByOS, or AutomaticByPlatform."
  }
}
variable "patch_assessment_mode" {
  description = "ImageDefault or AutomaticByPlatform."
  type        = string
  default     = "AutomaticByPlatform"
}
variable "hotpatching_enabled" {
  description = "Enable hotpatching (requires AutomaticByPlatform patch mode + VM agent)."
  type        = bool
  default     = false
}
variable "secure_boot_enabled" {
  description = "Enable Secure Boot (Trusted Launch)."
  type        = bool
  default     = true
}
variable "vtpm_enabled" {
  description = "Enable vTPM (Trusted Launch)."
  type        = bool
  default     = true
}
variable "encryption_at_host_enabled" {
  description = "Encrypt VM disks and cache at the host."
  type        = bool
  default     = true
}
variable "identity" {
  description = "Optional managed identity."
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}
variable "boot_diagnostics" {
  description = "Boot diagnostics. null disables; {} uses Azure-managed storage."
  type = object({
    storage_account_uri = optional(string)
  })
  default = null
}
variable "additional_capabilities" {
  description = "Additional VM capabilities (e.g. ultra_ssd_enabled)."
  type = object({
    ultra_ssd_enabled = optional(bool, false)
  })
  default = null
}
variable "os_disk" {
  description = "OS disk configuration."
  type = object({
    caching                   = string # None | ReadOnly | ReadWrite
    storage_account_type      = string # Standard_LRS | StandardSSD_LRS | Premium_LRS | ...
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
  description = "Tags applied to the VM."
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Optional custom Terraform operation timeouts for the Windows VM. Omitted values retain provider defaults."
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = {}
}
