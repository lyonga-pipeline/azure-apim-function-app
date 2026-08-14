variable "resource_group_name" {
  description = "Name of the resource group to place the VM's."
  type        = string
}

variable "location" {
  type        = string
  description = "Location of the resource group to place the VM."
  default     = "northcentralus"
}

variable "nic_name" {
  description = "Name of the network interface."
  type        = string
  default     = null
}

variable "ip_configuration_name" {
  description = "Name for the NIC IP configuration setting."
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

variable "subnet_id" {
  description = "ID of the subnet where the VM's reside."
  type        = string
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

variable "admin_username" {
  description = "The username of the local administrator used for the Virtual Machine."
  type        = string
}

variable "admin_password" {
  description = "The Password which should be used for the local-administrator on this Virtual Machine"
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

variable "source_image_reference" {
  description = "Provide a search on the image based on the details."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "os_disk" {
  description = "Provide a search on the image based on the details."
  type = object({
    name                 = string
    caching              = string
    storage_account_type = string
    disk_size_gb         = optional(number)
  })
}

variable "data_disks" {
  description = "List of data disks and their properties"
  type = list(object({
    name                 = string
    storage_account_type = string
    create_option        = string
    disk_size_gb         = number
    lun                  = number
    caching              = string
  }))
  default = []
}

variable "enable_ad_join" {
  type        = bool
  description = "Whether to enable AD join."
  default     = false
}

variable "active_directory_domain" {
  description = "Name of the Active Directory domain to join."
  type        = string
  default     = "agstar.local"
}

variable "ou_path" {
  description = "An organizational unit (OU) within an Active Directory to place the virtual machines."
  type        = string
  default     = "OU=Servers,OU=NP0,OU=NonProd,DC=agstar,DC=local"
}

variable "active_directory_username" {
  description = "Username of an account with permissions to bind machines to the Active Directory Domain."
  type        = string
  default     = "agstar\\svc_terraform"
}

variable "active_directory_password" {
  description = "Password of the account with permissions to bind machines to the Active Directory Domain."
  type        = string
  sensitive   = true
  default     = null
}

variable "sql_license_type" {
  description = "The SQL Server license type. Possible values are AHUB (Azure Hybrid Benefit), DR (Disaster Recovery), and PAYG (Pay-As-You-Go). Changing this forces a new resource to be created."
  type        = string
  default     = "PAYG"
}

variable "auto_backup" {
  description = "An auto_backup block as defined below. This block can be added to an existing resource, but removing this block forces a new resource to be created."
  type = object({
    encryption_password = optional(string, null)
    manual_schedule = object({
      full_backup_frequency           = string
      full_backup_start_hour          = number
      full_backup_window_in_hours     = number
      log_backup_frequency_in_minutes = number
      days_of_week                    = optional(set(string))
    })
    retention_period_in_days        = number
    storage_blob_endpoint           = string
    storage_account_access_key      = string
    system_databases_backup_enabled = optional(bool)
  })
  default = null
}

variable "auto_patching" {
  description = "An auto_patching block as defined below."
  type = object({
    day_of_week                            = string
    maintenance_window_starting_hour       = number
    maintenance_window_duration_in_minutes = number
  })
  default = null
}

variable "key_vault_credential" {
  description = "An key_vault_credential block as defined below."
  type = object({
    name                     = string
    key_vault_url            = string
    service_principal_name   = string
    service_principal_secret = string
  })
  default = null
}

variable "r_services_enabled" {
  description = "Should R Services be enabled?"
  type        = bool
  default     = false
}

variable "sql_connectivity_port" {
  description = " The SQL Server port"
  type        = number
  default     = 1433
}

variable "sql_connectivity_type" {
  description = "The connectivity type used for this SQL Server. Possible values are LOCAL, PRIVATE and PUBLIC"
  type        = string
  default     = "PRIVATE"
}

variable "sql_connectivity_update_password" {
  description = "The SQL Server sysadmin login password."
  type        = string
  sensitive   = true
}

variable "sql_connectivity_update_username" {
  description = "The SQL Server sysadmin login to create."
  type        = string
  sensitive   = true
}

variable "sql_instance" {
  description = "A sql_instance block as defined below."
  type = object({
    adhoc_workloads_optimization_enabled = optional(bool)
    collation                            = optional(string)
    instant_file_initialization_enabled  = optional(bool)
    lock_pages_in_memory_enabled         = optional(bool)
    max_dop                              = optional(number)
    max_server_memory_mb                 = optional(number)
    min_server_memory_mb                 = optional(number)
  })
  default = null
}

variable "storage_configuration" {
  description = "An storage_configuration block as defined below."
  type = object({
    disk_type                      = string
    storage_workload_type          = string
    system_db_on_data_disk_enabled = bool
    data_settings = object({
      default_file_path = string
      luns              = list(number)
    })
    log_settings = object({
      default_file_path = string
      luns              = list(number)
    })
    temp_db_settings = object({
      default_file_path      = string
      luns                   = list(number)
      data_file_count        = optional(number)
      data_file_size_mb      = optional(number)
      data_file_growth_in_mb = optional(number)
      log_file_size_mb       = optional(number)
      log_file_growth_mb     = optional(number)
    })
  })
  default = null
}

variable "assessment" {
  description = "An assessment block as defined below."
  type = object({
    enabled         = optional(bool)
    run_immediately = optional(bool)
    schedule = object({
      weekly_interval    = optional(number)
      monthly_occurrence = optional(number)
      day_of_week        = optional(string)
      start_time         = string
    })
  })
  default = null
}

variable "sql_virtual_machine_group_id" {
  description = "The ID of the SQL Virtual Machine Group that the SQL Virtual Machine belongs to."
  type        = string
  default     = null
}

variable "wsfc_domain_credential" {
  description = "value"
  type = object({
    cluster_bootstrap_account_password = string
    cluster_operator_account_password  = string
    sql_service_account_password       = string
  })
  default = null
}

variable "tags" {
  description = "A mapping of tags which should be assigned to this Virtual Machine."
  type        = map(string)
  default     = {}
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

variable "bypass_platform_safety_checks_on_user_schedule_enabled" {
  description = "Indicates whether to bypass platform safety checks when user schedule is enabled. This is required when the VMSS has more than 100 instances. Changing this forces a new resource to be created."
  type        = bool
  default     = false
}