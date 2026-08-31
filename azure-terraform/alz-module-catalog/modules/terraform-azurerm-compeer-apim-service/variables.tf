variable "name" {
  description = "API Management service name. Changing this forces a new resource."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the service is created in. Changing this forces a new resource."
  type        = string
}

variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}

variable "publisher_name" {
  description = "Publisher name shown in the developer portal and service notifications."
  type        = string
}

variable "publisher_email" {
  description = "Publisher email that receives service notifications."
  type        = string
}

variable "sku_name" {
  description = "SKU in `<tier>_<capacity>` form, e.g. Developer_1, Standard_2, Premium_3, Consumption_0."
  type        = string
  default     = "Developer_1"

  validation {
    condition     = can(regex("^(Consumption|Developer|Basic|Standard|Premium|BasicV2|StandardV2|PremiumV2)_[0-9]+$", var.sku_name))
    error_message = "sku_name must be `<tier>_<capacity>` (e.g. Developer_1, Premium_3)."
  }
}

variable "public_network_access_enabled" {
  description = "Whether the service is reachable from the public internet."
  type        = bool
  default     = false
}

variable "virtual_network_type" {
  description = "VNet integration mode: None, External (gateway public), or Internal (gateway private)."
  type        = string
  default     = "None"

  validation {
    condition     = contains(["External", "Internal", "None"], var.virtual_network_type)
    error_message = "virtual_network_type must be External, Internal, or None."
  }
}

variable "virtual_network_configuration" {
  description = "Subnet the service joins. Required when virtual_network_type is External or Internal."
  type = object({
    subnet_id = string
  })
  default = null
}

variable "identity" {
  description = "Managed identity. `type` is SystemAssigned, UserAssigned, or `SystemAssigned, UserAssigned`; supply identity_ids for the UserAssigned forms."
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null

  validation {
    condition     = var.identity == null ? true : contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity.type)
    error_message = "identity.type must be SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}

variable "security" {
  description = "Transport-security toggles for the gateway. Attribute names follow azurerm 4.x (`*_enabled`)."
  type = object({
    backend_ssl30_enabled                               = optional(bool)
    backend_tls10_enabled                               = optional(bool)
    backend_tls11_enabled                               = optional(bool)
    frontend_ssl30_enabled                              = optional(bool)
    frontend_tls10_enabled                              = optional(bool)
    frontend_tls11_enabled                              = optional(bool)
    tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled = optional(bool)
    tls_ecdhe_ecdsa_with_aes256_cbc_sha_ciphers_enabled = optional(bool)
    tls_ecdhe_rsa_with_aes128_cbc_sha_ciphers_enabled   = optional(bool)
    tls_ecdhe_rsa_with_aes256_cbc_sha_ciphers_enabled   = optional(bool)
    tls_rsa_with_aes128_cbc_sha256_ciphers_enabled      = optional(bool)
    tls_rsa_with_aes128_cbc_sha_ciphers_enabled         = optional(bool)
    tls_rsa_with_aes128_gcm_sha256_ciphers_enabled      = optional(bool)
    tls_rsa_with_aes256_cbc_sha256_ciphers_enabled      = optional(bool)
    tls_rsa_with_aes256_cbc_sha_ciphers_enabled         = optional(bool)
    tls_rsa_with_aes256_gcm_sha384_ciphers_enabled      = optional(bool)
    triple_des_ciphers_enabled                          = optional(bool)
  })
  default = null
}

variable "protocols" {
  description = "Client protocol toggles for the gateway."
  type = object({
    http2_enabled = optional(bool)
  })
  default = null
}

variable "sign_in" {
  description = "Developer portal sign-in policy."
  type = object({
    enabled = bool
  })
  default = null
}

variable "sign_up" {
  description = "Developer portal sign-up policy and terms of service."
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

variable "timeouts" {
  description = "Optional resource operation timeouts."
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = {}
}

variable "tags" {
  description = "Tags applied to the API Management service."
  type        = map(string)
  default     = {}
}
