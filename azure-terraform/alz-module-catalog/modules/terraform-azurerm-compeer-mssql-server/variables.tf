variable "name" {
  description = "The name of the Microsoft SQL Server. This needs to be globally unique within Azure."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Microsoft SQL Server."
  type        = string
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists."
  type        = string
}

variable "mssql_server_version" {
  description = "The version for the new server. Valid values are: 2.0 (for v11 server) and 12.0 (for v12 server)."
  type        = string
  validation {
    condition     = contains(["2.0", "12.0"], var.mssql_server_version)
    error_message = "The version can only be 2.0 (for v11 server) or 12.0 (for v12 server)."
  }
}

variable "administrator_login" {
  description = "The administrator login name for the new server."
  type        = string
  default     = null
}

variable "administrator_login_password" {
  description = "The password associated with the administrator_login user. Needs to comply with Azure's Password Policy."
  type        = string
  sensitive   = true
  default     = null
}

variable "connection_policy" {
  description = "The connection policy the server will use. Possible values are Default, Proxy, and Redirect."
  type        = string
  default     = "Default"
  validation {
    condition     = contains(["Default", "Proxy", "Redirect"], var.connection_policy)
    error_message = "The connection_policy can only be Default, Proxy, or Redirect."
  }
}

variable "transparent_data_encryption_key_vault_key_id" {
  description = "The fully versioned Key Vault Key URL to be used as the Customer Managed Key for the Transparent Data Encryption layer."
  type        = string
  default     = null
}

variable "minimum_tls_version" {
  description = "The Minimum TLS Version for all SQL Database and SQL Data Warehouse databases associated with the server."
  type        = string
  default     = "1.2"
  validation {
    condition     = contains(["1.0", "1.1", "1.2", "Disabled"], var.minimum_tls_version)
    error_message = "The minimum_tls_version can only be 1.0, 1.1, 1.2, or Disabled."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this server."
  type        = bool
  default     = false
}

variable "outbound_network_restriction_enabled" {
  description = "Whether outbound network traffic is restricted for this server."
  type        = bool
  default     = false
}

variable "primary_user_assigned_identity_id" {
  description = "Specifies the primary user managed identity id. Required if type is UserAssigned and should be combined with identity_ids."
  type        = string
  default     = null
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "identity" {
  description = "Identity configuration for SQL Server"
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default = null
  validation {
    condition     = var.identity == null ? true : contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity.type)
    error_message = "Valid values for identity_type are SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }
}

variable "azuread_administrator" {
  description = "Azure AD Administrator configuration for SQL Server"
  type = object({
    login_username              = string
    object_id                   = string
    tenant_id                   = optional(string)
    azuread_authentication_only = optional(bool)
  })
  default = null
}
