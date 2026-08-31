variable "administrator_login" {
  description = "The administrator login name for the new SQL Managed Instance."
  type        = string
}

variable "administrator_login_password" {
  description = "The password associated with the administrator_login user. Must comply with Azure's Password Policy."
  type        = string
  sensitive   = true
}

variable "license_type" {
  description = "What type of license the Managed Instance will use."
  type        = string
  validation {
    condition     = contains(["LicenseIncluded", "BasePrice"], var.license_type)
    error_message = "Valid values for license_type are LicenseIncluded and BasePrice."
  }
}

variable "location" {
  description = "The supported Azure location where the resource exists."
  type        = string
}

variable "name" {
  description = "The name of the SQL Managed Instance."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the SQL Managed Instance."
  type        = string
}

variable "sku_name" {
  description = "The SKU Name for the SQL Managed Instance."
  type        = string
  validation {
    condition     = contains(["GP_Gen4", "GP_Gen5", "GP_Gen8IM", "GP_Gen8IH", "BC_Gen4", "BC_Gen5", "BC_Gen8IM", "BC_Gen8IH"], var.sku_name)
    error_message = "Invalid SKU name. Check the accepted values."
  }
}

variable "storage_size_in_gb" {
  description = "Maximum storage space for the SQL Managed instance."
  type        = number
  validation {
    condition     = var.storage_size_in_gb % 32 == 0
    error_message = "Storage size should be a multiple of 32 (GB)."
  }
}

variable "subnet_id" {
  description = "The subnet resource ID that the SQL Managed Instance will be associated with."
  type        = string
}

variable "vcores" {
  description = "Number of cores assigned to the SQL Managed Instance."
  type        = number
  validation {
    condition     = contains([8, 16, 24, 4, 32, 40, 64, 80], var.vcores)
    error_message = "Invalid vcores value. Check the accepted values for Gen4 and Gen5 SKUs."
  }
}

variable "collation" {
  description = "Specifies how the SQL Managed Instance will be collated."
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "dns_zone_partner_id" {
  description = "The ID of the SQL Managed Instance which will share the DNS zone."
  type        = string
  default     = null
}

variable "maintenance_configuration_name" {
  description = "The name of the Public Maintenance Configuration window."
  type        = string
  default     = "SQL_Default"
}

variable "minimum_tls_version" {
  description = "The Minimum TLS Version."
  type        = string
  default     = "1.2"
  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "Valid values for minimum_tls_version are 1.0, 1.1, and 1.2."
  }
}

variable "proxy_override" {
  description = "Specifies how the SQL Managed Instance will be accessed."
  type        = string
  default     = "Default"
  validation {
    condition     = contains(["Default", "Proxy", "Redirect"], var.proxy_override)
    error_message = "Valid values for proxy_override are Default, Proxy, and Redirect."
  }
}

variable "public_data_endpoint_enabled" {
  description = "Is the public data endpoint enabled?"
  type        = bool
  default     = false
}

variable "storage_account_type" {
  description = "The storage account type used to store backups for this database."
  type        = string
  default     = "GRS"
  validation {
    condition     = contains(["GRS", "LRS", "ZRS"], var.storage_account_type)
    error_message = "Valid values for storage_account_type are GRS, LRS, and ZRS."
  }
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "timezone_id" {
  description = "The TimeZone ID that the SQL Managed Instance will operate in."
  type        = string
  default     = "UTC"
}

variable "identity" {
  description = "An identity block as defined below."
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default = null
  validation {
    condition     = var.identity == null ? true : contains(["SystemAssigned", "UserAssigned"], var.identity.type)
    error_message = "Valid values for identity type are SystemAssigned and UserAssigned."
  }
}
