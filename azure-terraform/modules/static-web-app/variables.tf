variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "sku_tier" {
  type    = string
  default = "Standard"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "sku_tier must be Free or Standard."
  }
}
variable "sku_size" {
  type    = string
  default = "Standard"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_size)
    error_message = "sku_size must be Free or Standard."
  }
}
variable "public_network_access_enabled" {
  type    = bool
  default = false
}
variable "preview_environments_enabled" {
  type    = bool
  default = false
}
variable "configuration_file_changes_enabled" {
  type    = bool
  default = false
}
variable "repository_url" {
  type    = string
  default = null
}
variable "repository_branch" {
  type    = string
  default = null
}
variable "repository_token" {
  type      = string
  default   = null
  sensitive = true
}
variable "basic_auth" {
  type = object({
    environments = string
    password     = string
  })
  default = null
}
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(set(string), [])
  })
  default = null

  validation {
    condition = var.identity == null || contains([
      "SystemAssigned",
      "UserAssigned",
      "SystemAssigned, UserAssigned"
    ], var.identity.type)
    error_message = "identity.type must be SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}
variable "app_settings" {
  type      = map(string)
  default   = {}
  sensitive = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
