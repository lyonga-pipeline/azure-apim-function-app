variable "resource_group_name" {
  description = "Name of the resource group to place the VM's."
  type        = string
}

variable "resource_group_location" {
  type        = string
  description = "Location of the resource group to place the VM."
  default     = "northcentralus"
}

variable "subnet_id" {
  description = "ID of the subnet where the VM's reside."
  type        = string
}

variable "nic_name" {
  description = "Name of the network interface."
  type        = string
  default     = null
}

variable "dns_servers" {
  description = "List of dns servers to use for network interface"
  type        = list(string)
  default     = []
}

#variable "enable_ip_forwarding" {
variable "ip_forwarding_enabled" {
  description = "Should IP Forwarding be enabled?"
  type        = bool
  default     = false
}

#variable "enable_accelerated_networking" {
variable "accelerated_networking_enabled" {
  description = "Should Accelerated Networking be enabled? Defaults to false."
  default     = true
}

variable "internal_dns_name_label" {
  description = "The (relative) DNS Name used for internal communications between Virtual Machines in the same Virtual Network."
  type        = string
  default     = null
}

variable "private_ip_address_allocation_type" {
  description = "The allocation method used for the Private IP Address. Possible values are Dynamic and Static."
  type        = string
  default     = "Dynamic"
}

variable "private_ip_address" {
  description = "The Static IP Address which should be used. This is valid only when `private_ip_address_allocation` is set to `Static` "
  type        = list(string)
  default     = null
}

variable "ip_configuration_name" {
  description = "Name for the NIC IP configuration setting."
  type        = string
  default     = null
}

variable "virtual_machine_name" {
  description = "The name of the virtual machine."
  type        = string
}

variable "virtual_machine_size" {
  description = "The Virtual Machine SKU for the Virtual Machine. Refer: https://learn.microsoft.com/en-us/azure/virtual-machines/sizes to know more on different sizes available."
  type        = string
  default     = "Standard_A2_v2"
}

variable "admin_username" {
  description = "The username of the local administrator used for the Virtual Machine."
  type        = string
}

variable "admin_password" {
  description = "The Password which should be used for the local-administrator on this Virtual Machine"
  type        = string
  default     = null
}

variable "source_image_id" {
  description = "The ID of an Image which each Virtual Machine should be based on"
  type        = string
}

variable "custom_data" {
  description = "Base64 encoded file of a bash script that gets run once by cloud-init upon VM creation"
  default     = null
}

variable "automatic_updates_enabled" {
  description = "Specifies if Automatic Updates are Enabled for the Windows Virtual Machine."
  type        = bool
  default     = false
}

variable "enable_encryption_at_host" {
  description = " Should all of the disks (including the temp disk) attached to this Virtual Machine be encrypted by enabling Encryption at Host?"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "The Zone in which this Virtual Machine should be created. Conflicts with availability set and shouldn't use both"
  type        = string
  default     = null
}

variable "patch_mode" {
  description = "Specifies the mode of in-guest patching to this Windows Virtual Machine. Possible values are `Manual`, `AutomaticByOS` and `AutomaticByPlatform`"
  default     = "AutomaticByOS"
}

variable "patch_assessment_mode" {
  description = "Specifies the mode of in-guest patch assessment to this Windows Virtual Machine. Possible values are `ImageDefault`, `AutomaticByOS` and `AutomaticByPlatform`"
  default     = "ImageDefault"
}

variable "license_type" {
  description = "Specifies the type of on-premise license which should be used for this Virtual Machine. Possible values are None, Windows_Client and Windows_Server."
  default     = "Windows_Server"
}

variable "source_image_reference" {
  description = "Provide a search on the image based on the details."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = null
}

variable "os_disk_storage_account_type" {
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values are `Standard_LRS`, `StandardSSD_LRS`, `Premium_LRS`, `StandardSSD_ZRS` and `Premium_ZRS`. Changing this forces a new resource to be created."
  type        = string
  default     = "StandardSSD_LRS"
}

variable "os_disk_caching" {
  description = "The Type of Caching which should be used for the Internal OS Disk. Possible values are `None`, `ReadOnly` and `ReadWrite`."
  type        = string
  default     = "ReadWrite"
}

variable "disk_encryption_set_id" {
  description = "The ID of the Disk Encryption Set which should be used to Encrypt this OS Disk. Conflicts with `secure_vm_disk_encryption_set_id`."
  type        = string
  default     = null
}

variable "disk_size_gb" {
  description = "The Size of the Internal OS Disk in GB, if you wish to vary from the size used in the image this Virtual Machine is sourced from."
  type        = number
  default     = null
}

variable "enable_os_disk_write_accelerator" {
  description = "Should Write Accelerator be Enabled for this OS Disk?"
  type        = bool
  default     = false
}

variable "os_disk_name" {
  description = "The name which should be used for the Internal OS Disk. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "managed_identity_type" {
  description = "Specifies the type of Managed Service Identity that should be configured on this Windows Virtual Machine. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both)."
  type        = string
  default     = null
}

variable "managed_identity_ids" {
  description = "Specifies a list of User Assigned Managed Identity IDs to be assigned to this Windows Virtual Machine."
  type        = list(string)
  default     = null
}

variable "enable_availability_set" {
  description = "Whether to create availability set for the VM?"
  type        = bool
  default     = true
}

variable "availability_set_name" {
  description = "Availability set name."
  type        = string
  default     = null
}

variable "platform_fault_domain_count" {
  description = "Specifies the number of fault domains that are used"
  type        = number
  default     = 3
}

variable "platform_update_domain_count" {
  description = "Specifies the number of update domains that are used"
  type        = number
  default     = 5
}

variable "managed_availability_set" {
  description = "Specifies whether the availability set is managed or not."
  type        = bool
  default     = true
}

variable "data_disks" {
  description = "Managed Data Disks for azure virtual machine"
  type = list(object({
    name                 = string
    storage_account_type = string
    disk_size_gb         = number
    create_option        = string
    drive_letter         = optional(string)
    drive_label          = optional(string)
  }))
  default = []
}

variable "enable_disk_extension" {
  description = "Enable/Disable data disk drive letter extension"
  type        = bool
  default     = false
}

variable "vm_tags" {
  description = "A map of vm tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "ext_tags" {
  description = "A map of vm extension tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "nic_tags" {
  description = "A map of vm nic tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "mngd_tags" {
  description = "A map of vm managed disk tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "avs_tags" {
  description = "A map of vm availability set tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "random_password_length" {
  description = "The desired length of random password created by this module"
  type        = number
  default     = 24
}

variable "enable_ad_join" {
  type        = bool
  description = "Whether to enable AD join."
  default     = false
}

variable "active_directory_domain" {
  description = "Name of the Active Directory domain to join."
  type        = string
}

variable "ou_path" {
  description = "An organizational unit (OU) within an Active Directory to place the virtual machines."
  type        = string
  default     = null
}

variable "active_directory_username" {
  description = "Username of an account with permissions to bind machines to the Active Directory Domain."
  type        = string

}

variable "active_directory_password" {
  description = "Password of the account with permissions to bind machines to the Active Directory Domain."
  type        = string
  sensitive   = true
}

variable "additional_ip_configuration" {
  description = "Additional IP configuration for the NIC."
  type = list(object({
    name                          = string
    private_ip_address_allocation = optional(string, "Static")
    private_ip_address            = optional(string)
    subnet_id                     = optional(string)
  }))
  default = []
}

variable "availability_set_id" {
  description = "Optional existing Availability Set ID"
  type        = string
  default     = null
}

variable "bypass_platform_safety_checks_on_user_schedule_enabled" {
  description = "Whether to bypass platform safety checks on user schedule enabled or not."
  type        = bool
  default     = false
}

variable "boot_diagnostics" {
  description = "Configuration for boot diagnostics. Set to null to disable boot diagnostics. When enabled, you can optionally specify a storage_account_uri."
  type = object({
    storage_account_uri = optional(string)
  })
  default = null
}