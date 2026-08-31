variable "name" {
  description = "Name of the user-assigned managed identity. Changing this forces a new resource."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string
}

variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}

variable "tags" {
  description = "Tags applied to the identity."
  type        = map(string)
  default     = {}
}
