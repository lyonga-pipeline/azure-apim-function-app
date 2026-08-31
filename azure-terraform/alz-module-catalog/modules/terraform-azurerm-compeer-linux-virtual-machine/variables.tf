variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string
}
variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}
variable "name" {
  description = "VM name. Changing this forces a new resource."
  type        = string
}
variable "vm_size" {
  description = "VM SKU size."
  type        = string
  default     = "Standard_D2s_v5"
}
variable "network_interface_ids" {
  description = "NIC resource IDs to attach (first is primary). NICs are caller-owned."
  type        = list(string)
}
variable "admin_username" {
  description = "Local administrator username."
  type        = string
  default     = "azureadmin"
}
variable "admin_password" {
  description = "Local admin password. Required only when disable_password_authentication = false. Stored in state."
  type        = string
  sensitive   = true
  default     = null
}
variable "disable_password_authentication" {
  description = "Disable password auth and require SSH keys (recommended)."
  type        = bool
  default     = true
  sensitive   = true
}
variable "admin_ssh_keys" {
  description = "SSH public keys keyed by a stable logical name; required when password auth is disabled."
  type        = map(object({ username = optional(string), public_key = string }))
  default     = {}
}
variable "computer_name" {
  description = "OS hostname. Defaults to name."
  type        = string
  default     = null
}
variable "availability_set_id" {
  description = "Availability set. Mutually exclusive with zone."
  type        = string
  default     = null
}
variable "zone" {
  description = "Availability zone. Mutually exclusive with availability_set_id. ForceNew."
  type        = string
  default     = null
}
variable "source_image_id" {
  description = "Image ID. Mutually exclusive with source_image_reference."
  type        = string
  default     = null
}
variable "source_image_reference" {
  description = "Marketplace image reference. Mutually exclusive with source_image_id."
  type        = object({ publisher = string, offer = string, sku = string, version = string })
  default     = null
}
variable "plan" {
  description = "Marketplace plan for images that require one."
  type        = object({ name = string, publisher = string, product = string })
  default     = null
}
variable "os_disk" {
  description = "OS disk configuration."
  type        = object({ caching = string, storage_account_type = string, name = optional(string), disk_encryption_set_id = optional(string), disk_size_gb = optional(number), write_accelerator_enabled = optional(bool) })
  default     = { caching = "ReadWrite", storage_account_type = "Premium_LRS" }
}
variable "identity" {
  description = "Optional managed identity."
  type        = object({ type = string, identity_ids = optional(list(string), []) })
  default     = null
}
variable "boot_diagnostics" {
  description = "Boot diagnostics. null disables; {} uses Azure-managed storage."
  type        = object({ storage_account_uri = optional(string) })
  default     = null
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
variable "patch_mode" {
  description = "ImageDefault or AutomaticByPlatform."
  type        = string
  default     = "ImageDefault"

  validation {
    condition     = contains(["ImageDefault", "AutomaticByPlatform"], var.patch_mode)
    error_message = "patch_mode must be ImageDefault or AutomaticByPlatform."
  }
}
variable "patch_assessment_mode" {
  description = "ImageDefault or AutomaticByPlatform."
  type        = string
  default     = "ImageDefault"
}
variable "encryption_at_host_enabled" {
  description = "Encrypt VM disks and cache at the host."
  type        = bool
  default     = null
}
variable "secure_boot_enabled" {
  description = "Enable Secure Boot (Trusted Launch)."
  type        = bool
  default     = null
}
variable "vtpm_enabled" {
  description = "Enable vTPM (Trusted Launch)."
  type        = bool
  default     = null
}
variable "license_type" {
  description = "RHEL_BYOS, SLES_BYOS, or None."
  type        = string
  default     = null
}
variable "user_data" {
  description = "Base64 user data."
  type        = string
  default     = null
}
variable "custom_data" {
  description = "Base64 cloud-init custom data. Stored in state."
  type        = string
  default     = null
  sensitive   = true
}
variable "tags" {
  description = "Tags applied to the VM."
  type        = map(string)
  default     = {}
}
variable "timeouts" {
  description = "Optional resource operation timeouts."
  type        = object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) })
  default     = {}
}
