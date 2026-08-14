variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location/region to keep all your network resources.'"
}

variable "storage_account_name" {
  description = "The name of the storage account"
  type        = string
}

variable "data_lake_gen2_fs_name" {
  description = "The name of the gen2 file system"
  type        = string
}

/* variable "key_vault_name" {
  description = "The name of the key vault"
  type        = string
}

variable "key_name" {
  description = "The name of the key in the key vault"
  type        = string
} */

variable "synapse_workspace_name" {
  description = "The name of the Synapse workspace"
  type        = string
}

variable "sql_admin_login" {
  description = "The login name for SQL administrator"
  type        = string
}

variable "sql_admin_password" {
  description = "The password for SQL administrator"
  type        = string
}

/* variable "customer_managed_key_name" {
  description = "The name of the customer-managed key"
  type        = string
} */

variable "aad_admin_login" {
  description = "The login name for Azure AD administrator"
  type        = string
}

variable "aad_admin_object_id" {
  description = "The object ID for Azure AD administrator"
  type        = string
}

variable "aad_admin_tenant_id" {
  description = "The tenant ID for Azure AD administrator"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "synapse_workspace_identity" {
  description = "Synapse Workspace Identity Type"
  type        = string
}

variable "synapse_workspace_key_active" {
  description = "Whether Synapse Workspace key needs to activated"
  type        = bool
}