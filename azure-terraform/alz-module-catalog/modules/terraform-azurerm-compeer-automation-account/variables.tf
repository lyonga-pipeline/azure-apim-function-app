variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create Automation Account"
}

variable "resource_group_location" {
  type        = string
  description = "Location of the resource group"
  default     = "eastus2"
}

variable "automation_account_name" {
  type        = string
  description = "Name of the Automation Account."
}

variable "automation_account_sku" {
  type        = string
  description = "SKU for Automation Account."
  default     = "Basic"
}

variable "local_auth_enabled" {
  type        = bool
  description = "Whether request using non-AAD authentication are blocked."
  default     = true
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether public network access is allowed for autiomation account."
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) A mapping of tags to assign to the resource."
  nullable    = false
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default     = null
  description = <<-DESCRIPTION
    type = object({
      type         = (Required) The type of the Identity. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned`.
      identity_ids = (Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this OpenAI Account.
    })
  DESCRIPTION
}
