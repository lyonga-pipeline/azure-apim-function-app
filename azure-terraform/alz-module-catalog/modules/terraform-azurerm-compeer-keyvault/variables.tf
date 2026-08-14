variable "name" {
  description = "Specifies the name of the Key Vault.Changing this forces a new resource to be created. The name must be globally unique. If the vault is in a recoverable state then the vault will need to be purged before reusing the name."
  type        = string
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Key Vault. Changing this forces a new resource to be created."
  type        = string
}

variable "sku_name" {
  description = "The Name of the SKU used for this Key Vault. Possible values are standard and premium."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], lower(var.sku_name))
    error_message = "sku_name must be either standard or premium."
  }
}

# variable "tenant_id" {
#   description = "The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault."
#   type        = string
# }

variable "access_policies" {
  description = "Access policies for the key vault. Used only when RBAC authorization is disabled."
  type = list(object({
    tenant_id               = string
    object_id               = string
    application_id          = optional(string)
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    certificate_permissions = optional(list(string))
    storage_permissions     = optional(list(string))
  }))
  default = []
}

variable "rbac_authorization_enabled" {
  description = "Enable Azure RBAC authorization for the Key Vault. Prefer true for enterprise deployments."
  type        = bool
  default     = null
}

variable "enable_rbac_authorization" {
  description = "Deprecated compatibility input. Use rbac_authorization_enabled instead."
  type        = bool
  default     = null
}

variable "enabled_for_deployment" {
  description = "Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault."
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys."
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault."
  type        = bool
  default     = false
}

variable "network_acls" {
  description = "Network ACLs for the key vault"
  type = object({
    default_action             = string
    bypass                     = string
    ip_rules                   = optional(list(string))
    virtual_network_subnet_ids = optional(list(string))
  })
  default = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  validation {
    condition     = var.network_acls == null || contains(["Allow", "Deny"], var.network_acls.default_action)
    error_message = "network_acls.default_action must be Allow or Deny."
  }

  validation {
    condition     = var.network_acls == null || contains(["AzureServices", "None"], var.network_acls.bypass)
    error_message = "network_acls.bypass must be AzureServices or None."
  }
}

## Note:
## Once Purge Protection has been Enabled it's not possible to Disable it. 
## Support for disabling purge protection is being tracked in this Azure API issue. 
## Deleting the Key Vault with Purge Protection Enabled will schedule the Key Vault 
## to be deleted (which will happen by Azure in the configured number of days, 
## currently 90 days - which will be configurable in Terraform in the future).

variable "purge_protection_enabled" {
  description = "Is Purge Protection enabled for this Key Vault?"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this Key Vault. Defaults to true."
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days."
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "contacts" {
  description = "Optional Key Vault certificate contacts."
  type = list(object({
    email = string
    name  = optional(string)
    phone = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
