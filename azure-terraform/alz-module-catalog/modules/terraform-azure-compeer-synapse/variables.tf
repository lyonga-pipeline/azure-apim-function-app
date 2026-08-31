variable "storage_data_lake_gen2_filesystem_id" {
  description = "ID of an externally managed ADLS Gen2 filesystem the workspace roots at."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group the workspace is created in."
  type        = string
}

variable "location" {
  description = "Azure region for the workspace."
  type        = string
}

variable "synapse_workspace_name" {
  description = "Name of the Synapse workspace."
  type        = string
}

variable "sql_admin_login" {
  description = "SQL administrator login name."
  type        = string
}

variable "sql_admin_password" {
  description = "SQL administrator password. Stored in Terraform state - protect the backend accordingly."
  type        = string
  sensitive   = true
}

variable "aad_admin" {
  description = <<-EOT
    Optional Entra ID administrator for the workspace. null means the module does
    not manage the directory administrator (it can be set out of band or by a
    companion). Managed via azurerm_synapse_workspace_aad_admin.
  EOT
  type = object({
    login     = string
    object_id = string
    tenant_id = string
  })
  default = null
}

variable "synapse_workspace_identity" {
  description = "Managed identity type for the workspace (SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned)."
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.synapse_workspace_identity)
    error_message = "synapse_workspace_identity must be SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}

variable "managed_virtual_network_enabled" {
  description = "Whether to create the workspace inside a managed virtual network."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether the workspace is reachable from public networks. Defaults closed; use the private-endpoint companion."
  type        = bool
  default     = false
}

variable "data_exfiltration_protection_enabled" {
  description = "Enable workspace data exfiltration protection."
  type        = bool
  default     = null
}

variable "tags" {
  description = "Tags applied to the workspace."
  type        = map(string)
  default     = {}
}
