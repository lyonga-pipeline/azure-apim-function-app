variable "name" {
  description = "Name of the Key Vault managed storage account object. Changing this forces a new resource."
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault that manages this storage account. Changing this forces a new resource."
  type        = string
}

variable "storage_account_id" {
  description = "Resource ID of the storage account to be managed by Key Vault."
  type        = string
}

variable "storage_account_key" {
  description = "Which storage account key (key1/key2) Key Vault manages and rotates."
  type        = string
  default     = "key1"

  validation {
    condition     = contains(["key1", "key2"], var.storage_account_key)
    error_message = "storage_account_key must be key1 or key2."
  }
}

variable "regenerate_key_automatically" {
  description = "Whether Key Vault regenerates the storage account key automatically."
  type        = bool
  default     = true
}

variable "regeneration_period" {
  description = "ISO 8601 duration between automatic key regenerations."
  type        = string
  default     = "P90D"
}

variable "sas_token_definitions" {
  description = "Optional SAS token definitions keyed by stable name."
  type = map(object({
    sas_template_uri = string
    sas_type         = string
    validity_period  = string
    tags             = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to the managed storage account object."
  type        = map(string)
  default     = {}
}
