variable "virtual_machine_id" {
  description = "ID of an existing Windows VM registered as a SQL virtual machine."
  type        = string
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

variable "wsfc_domain_credential" {
  description = "value"
  type = object({
    cluster_bootstrap_account_password = string
    cluster_operator_account_password  = string
    sql_service_account_password       = string
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

variable "sql_connectivity_port" {
  description = " The SQL Server port"
  type        = number
  default     = 1433
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

variable "sql_virtual_machine_group_id" {
  description = "The ID of the SQL Virtual Machine Group that the SQL Virtual Machine belongs to."
  type        = string
  default     = null
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

variable "sql_connectivity_type" {
  description = "The connectivity type used for this SQL Server. Possible values are LOCAL, PRIVATE and PUBLIC"
  type        = string
  default     = "PRIVATE"

  validation {
    condition     = contains(["LOCAL", "PRIVATE", "PUBLIC"], var.sql_connectivity_type)
    error_message = "sql_connectivity_type must be LOCAL, PRIVATE or PUBLIC."
  }
}

variable "sql_connectivity_update_username" {
  description = "The SQL Server sysadmin login to create. Required when sql_connectivity_type is PRIVATE or PUBLIC."
  type        = string
  sensitive   = true
  default     = null
}

variable "sql_license_type" {
  description = "The SQL Server license type. Possible values are AHUB (Azure Hybrid Benefit), DR (Disaster Recovery), and PAYG (Pay-As-You-Go). Changing this forces a new resource to be created."
  type        = string
  default     = "PAYG"

  validation {
    condition     = contains(["AHUB", "DR", "PAYG"], var.sql_license_type)
    error_message = "sql_license_type must be AHUB, DR or PAYG."
  }
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

variable "sql_connectivity_update_password" {
  description = "The SQL Server sysadmin login password. Stored in state. Required when sql_connectivity_type is PRIVATE or PUBLIC."
  type        = string
  sensitive   = true
  default     = null
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
