variable "name" {
  description = "Resource group name. Changing this forces a new resource."
  type        = string

  validation {
    condition     = can(regex("^[-\\w._()]{1,90}$", var.name)) && !can(regex("\\.$", var.name))
    error_message = "Resource group name must be 1-90 chars of letters, digits, - _ . ( ), and not end with a period."
  }
}

variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}

variable "tags" {
  description = "Tags applied to the resource group."
  type        = map(string)
  default     = {}
}
