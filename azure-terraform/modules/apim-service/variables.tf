variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "publisher_name" { type = string }
variable "publisher_email" { type = string }
variable "sku_name" {
  type    = string
  default = "Developer_1"
}
variable "public_network_access_enabled" {
  type    = bool
  default = false
}
variable "virtual_network_type" {
  type    = string
  default = "None"
  validation {
    condition     = contains(["External", "Internal", "None"], var.virtual_network_type)
    error_message = "virtual_network_type must be External, Internal, or None."
  }
}
variable "virtual_network_configuration" {
  type = object({
    subnet_id = string
  })
  default = null
}
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}
variable "security" {
  type = object({
    enable_backend_ssl30                                = optional(bool)
    enable_backend_tls10                                = optional(bool)
    enable_backend_tls11                                = optional(bool)
    enable_frontend_ssl30                               = optional(bool)
    enable_frontend_tls10                               = optional(bool)
    enable_frontend_tls11                               = optional(bool)
    tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled = optional(bool)
  })
  default = null
}
variable "protocols" {
  type = object({
    enable_http2 = optional(bool)
  })
  default = null
}
variable "sign_in" {
  type = object({
    enabled = bool
  })
  default = null
}
variable "sign_up" {
  type = object({
    enabled = bool
    terms_of_service = optional(object({
      consent_required = optional(bool, false)
      enabled          = optional(bool, false)
      text             = optional(string)
    }))
  })
  default = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
