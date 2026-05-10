variable "api_management_id" { type = string }
variable "gateway" {
  type = map(object({
    certificate                     = optional(string)
    certificate_password            = optional(string)
    default_ssl_binding             = optional(bool)
    key_vault_certificate_id        = optional(string)
    negotiate_client_certificate    = optional(bool)
    ssl_keyvault_identity_client_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for config in values(var.gateway) :
      !(
        try(config.certificate, null) != null &&
        try(config.key_vault_certificate_id, null) != null
      )
    ])
    error_message = "Each gateway custom domain entry must set either certificate or key_vault_certificate_id, not both."
  }
}
variable "developer_portal" {
  type = map(object({
    certificate                     = optional(string)
    certificate_password            = optional(string)
    key_vault_certificate_id        = optional(string)
    negotiate_client_certificate    = optional(bool)
    ssl_keyvault_identity_client_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for config in values(var.developer_portal) :
      !(
        try(config.certificate, null) != null &&
        try(config.key_vault_certificate_id, null) != null
      )
    ])
    error_message = "Each developer_portal custom domain entry must set either certificate or key_vault_certificate_id, not both."
  }
}
variable "management" {
  type = map(object({
    certificate                     = optional(string)
    certificate_password            = optional(string)
    key_vault_certificate_id        = optional(string)
    negotiate_client_certificate    = optional(bool)
    ssl_keyvault_identity_client_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for config in values(var.management) :
      !(
        try(config.certificate, null) != null &&
        try(config.key_vault_certificate_id, null) != null
      )
    ])
    error_message = "Each management custom domain entry must set either certificate or key_vault_certificate_id, not both."
  }
}
variable "portal" {
  type = map(object({
    certificate                     = optional(string)
    certificate_password            = optional(string)
    key_vault_certificate_id        = optional(string)
    negotiate_client_certificate    = optional(bool)
    ssl_keyvault_identity_client_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for config in values(var.portal) :
      !(
        try(config.certificate, null) != null &&
        try(config.key_vault_certificate_id, null) != null
      )
    ])
    error_message = "Each portal custom domain entry must set either certificate or key_vault_certificate_id, not both."
  }
}
variable "scm" {
  type = map(object({
    certificate                     = optional(string)
    certificate_password            = optional(string)
    key_vault_certificate_id        = optional(string)
    negotiate_client_certificate    = optional(bool)
    ssl_keyvault_identity_client_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for config in values(var.scm) :
      !(
        try(config.certificate, null) != null &&
        try(config.key_vault_certificate_id, null) != null
      )
    ])
    error_message = "Each scm custom domain entry must set either certificate or key_vault_certificate_id, not both."
  }
}
