variable "name" {
  type        = string
  description = "Data Collection Endpoint name."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "kind" {
  type        = string
  description = "Data Collection Endpoint kind."
  default     = null
}

variable "description" {
  type        = string
  description = "Data Collection Endpoint description."
  default     = null
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether public network access is enabled."
  default     = null
}

variable "timeouts" {
  type = object({
    create = optional(string)
    update = optional(string)
    read   = optional(string)
    delete = optional(string)
  })
  default = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply."
  default     = {}
}
