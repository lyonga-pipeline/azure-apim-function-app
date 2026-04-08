variable "name" {
  description = "Virtual machine name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that hosts the VM and dependent resources."
  type        = string
}

variable "location" {
  description = "Azure region for the VM."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID used by the primary network interface."
  type        = string
}

variable "admin_username" {
  description = "Local administrator username."
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Local administrator password. Use a secret manager or pipeline secret."
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
    error_message = "admin_password must be at least 14 characters and include upper, lower, numeric, and special characters."
  }
}

variable "computer_name" {
  description = "Optional guest computer name. Defaults to the VM name."
  type        = string
  default     = null

  validation {
    condition     = try(length(var.computer_name) <= 15, true)
    error_message = "computer_name must be 15 characters or fewer for Windows."
  }
}

variable "vm_size" {
  description = "Azure VM SKU."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "image" {
  description = "Marketplace image reference."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })

  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

variable "license_type" {
  description = "Bring-your-own-license setting or Windows_Server."
  type        = string
  default     = "Windows_Server"
}

variable "timezone" {
  description = "Guest OS timezone."
  type        = string
  default     = "UTC"
}

variable "provision_vm_agent" {
  description = "Whether the Azure VM agent should be provisioned."
  type        = bool
  default     = true
}

variable "allow_extension_operations" {
  description = "Whether VM extensions can be installed after provisioning."
  type        = bool
  default     = false
}

variable "enable_automatic_updates" {
  description = "Enable Windows Update."
  type        = bool
  default     = true
}

variable "patch_mode" {
  description = "Patch orchestration mode."
  type        = string
  default     = "AutomaticByPlatform"

  validation {
    condition     = contains(["AutomaticByOS", "AutomaticByPlatform", "Manual"], var.patch_mode)
    error_message = "patch_mode must be one of AutomaticByOS, AutomaticByPlatform, or Manual."
  }
}

variable "patch_assessment_mode" {
  description = "Patch assessment mode."
  type        = string
  default     = "AutomaticByPlatform"

  validation {
    condition     = contains(["AutomaticByPlatform", "ImageDefault"], var.patch_assessment_mode)
    error_message = "patch_assessment_mode must be AutomaticByPlatform or ImageDefault."
  }
}

variable "hotpatching_enabled" {
  description = "Enable hotpatching when supported by the selected image and patch mode."
  type        = bool
  default     = false
}

variable "secure_boot_enabled" {
  description = "Enable secure boot for Gen2 images."
  type        = bool
  default     = true
}

variable "vtpm_enabled" {
  description = "Enable virtual TPM for Gen2 images."
  type        = bool
  default     = true
}

variable "encryption_at_host_enabled" {
  description = "Enable encryption at host."
  type        = bool
  default     = true
}

variable "ultra_ssd_enabled" {
  description = "Enable Ultra SSD capability."
  type        = bool
  default     = false
}

variable "zone" {
  description = "Availability zone."
  type        = string
  default     = null
}

variable "identity_type" {
  description = "Managed identity mode."
  type        = string
  default     = "SystemAssigned"

  validation {
    condition = contains([
      "None",
      "SystemAssigned",
      "UserAssigned",
      "SystemAssigned, UserAssigned"
    ], var.identity_type)
    error_message = "identity_type must be None, SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }
}

variable "identity_ids" {
  description = "User-assigned identity IDs."
  type        = list(string)
  default     = []
}

variable "boot_diagnostics_storage_account_uri" {
  description = "Optional storage account blob endpoint for boot diagnostics."
  type        = string
  default     = null
}

variable "private_ip_address_allocation" {
  description = "Dynamic or Static private IP allocation."
  type        = string
  default     = "Dynamic"

  validation {
    condition     = contains(["Dynamic", "Static"], var.private_ip_address_allocation)
    error_message = "private_ip_address_allocation must be Dynamic or Static."
  }
}

variable "private_ip_address" {
  description = "Private IP address when using Static allocation."
  type        = string
  default     = null
}

variable "public_ip_address_id" {
  description = "Optional public IP resource ID. Leave null for private-only deployments."
  type        = string
  default     = null
}

variable "network_security_group_id" {
  description = "Optional network security group ID to associate to the NIC."
  type        = string
  default     = null
}

variable "application_security_group_ids" {
  description = "Application security groups to associate with the NIC."
  type        = list(string)
  default     = []
}

variable "enable_accelerated_networking" {
  description = "Enable accelerated networking on the primary NIC."
  type        = bool
  default     = true
}

variable "enable_ip_forwarding" {
  description = "Enable IP forwarding on the primary NIC."
  type        = bool
  default     = false
}

variable "dns_servers" {
  description = "Optional custom DNS server list for the NIC."
  type        = list(string)
  default     = null
}

variable "os_disk_name" {
  description = "Optional custom OS disk name."
  type        = string
  default     = null
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB."
  type        = number
  default     = 128
}

variable "os_disk_storage_account_type" {
  description = "OS disk storage account type."
  type        = string
  default     = "Premium_LRS"
}

variable "os_disk_caching" {
  description = "OS disk caching mode."
  type        = string
  default     = "ReadWrite"
}

variable "data_disks" {
  description = "Managed data disks to attach."
  type = map(object({
    size_gb                = number
    lun                    = number
    storage_account_type   = optional(string, "Premium_LRS")
    caching                = optional(string, "ReadOnly")
    create_option          = optional(string, "Empty")
    disk_encryption_set_id = optional(string)
  }))
  default = {}
}

variable "disk_encryption_set_id" {
  description = "Disk Encryption Set resource ID used for managed data disks."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources in the module."
  type        = map(string)
  default     = {}
}
