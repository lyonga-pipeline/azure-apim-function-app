variable "create_app_config" {
  description = "Flag to control the creation of App Configuration"
  default     = false
}

variable "create_app_config_feature" {
  description = "Flag to control the creation of App Configuration Feature"
  default     = false
}

variable "create_app_config_key" {
  description = "Flag to control the creation of App Configuration Key"
  default     = false
}

variable "app_config_name" {
  description = "Specifies the name of the App Configuration. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the App Configuration. Changing this forces a new resource to be created."
  type        = string
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "app_config_sku" {
  description = "The SKU name of the App Configuration. Possible values are free and standard"
  type        = string
  default     = "free"
}

variable "app_config_local_auth" {
  description = "Whether local authentication methods is enabled. Defaults to true."
  type        = bool
  default     = true
}

variable "app_config_public_access" {
  description = "The Public Network Access setting of the App Configuration."
  type        = string
  default     = false
}

variable "app_config_purge_protection" {
  description = "Whether Purge Protection is enabled. This field only works for standard"
  type        = bool
  default     = false
}

variable "app_config_soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted. This field only works for standard sku."
  type        = number
  default     = 1
}

variable "identity" {
  description = "value"
  type = list(object({
    type         = string
    identity_ids = optional(string)
  }))
  default = null
}

variable "encryption" {
  description = "value"
  type = list(object({
    key_vault_key_identifier = optional(string)
    identity_client_id       = optional(string)
  }))
  default = null
}

variable "app_config_tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = null
}

variable "feature_description" {
  description = "The description of the App Configuration Feature."
  type        = string
  default     = null
}

variable "feature_enabled" {
  description = "The status of the App Configuration Feature."
  type        = bool
  default     = false
}

variable "feature_key" {
  description = "The key of the App Configuration Feature. The value for name will be used if this is unspecified. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "feature_label" {
  description = "The label of the App Configuration Feature. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "feature_locked" {
  description = "Should this App Configuration Feature be Locked to prevent changes?"
  type        = bool
  default     = false
}

variable "feature_name" {
  description = "The name of the App Configuration Feature. Changing this forces a new resource to be created."
  type        = string
  default     = ""
}

variable "percentage_filter_value" {
  description = "A list of one or more numbers representing the value of the percentage required to enable this feature."
  type        = number
  default     = 0
}

variable "feature_tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = null
}

variable "targeting_filter" {
  description = "A targeting_filter block represents a feature filter of type Microsoft.Targeting"
  type = object({
    default_rollout_percentage = optional(number),
    users                      = optional(list(string)),
    groups = list(object({
      name               = string,
      rollout_percentage = number
    }))
  })
  default = null
}

variable "timewindow_filter" {
  description = "A block representing a feature filter of type Microsoft.TimeWindow."
  type = object({
    start = optional(string),
    end   = optional(string)
  })
  default = {}
}

# Variables for azurerm_app_configuration_key
variable "app_config_key_name" {
  description = "The name of the App Configuration Key to create."
  type        = string
  default     = ""
}

variable "app_config_key_content_type" {
  description = "The content type of the App Configuration Key."
  type        = string
  default     = null
}

variable "app_config_key_label" {
  description = "The label of the App Configuration Key."
  type        = string
  default     = null
}

variable "app_config_key_value" {
  description = "The value of the App Configuration Key."
  type        = string
  default     = null
}

variable "app_config_key_locked" {
  description = "Should this App Configuration Key be Locked to prevent changes?"
  type        = bool
  default     = false
}

variable "app_config_key_type" {
  description = "The type of the App Configuration Key."
  type        = string
  default     = "kv"
}

variable "app_config_key_vault_key_reference" {
  description = "The ID of the vault secret this App Configuration Key refers to, when type is set to vault."
  type        = string
  default     = null
}

variable "app_config_key_tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = null
}