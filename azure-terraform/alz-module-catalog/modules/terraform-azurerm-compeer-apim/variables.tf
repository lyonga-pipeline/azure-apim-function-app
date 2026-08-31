variable "name" {
  description = "Name of the API Management service. Changing this forces a new resource."
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
  description = "Publisher name shown in the developer portal."
  type        = string
}
variable "publisher_email" {
  description = "Publisher email for service notifications."
  type        = string
}
variable "sku_name" {
  description = "SKU in <tier>_<capacity> form, e.g. Developer_1, Standard_2, Premium_3."
  type        = string
  default     = "Developer_1"

  validation {
    condition     = can(regex("^(Consumption|Developer|Basic|Standard|Premium|BasicV2|StandardV2|PremiumV2)_[0-9]+$", var.sku_name))
    error_message = "sku_name must be <tier>_<capacity>, e.g. Developer_1 or Premium_3."
  }
}
variable "public_network_access_enabled" {
  description = "Whether the service is reachable from public networks. Defaults closed."
  type        = bool
  default     = false
}
variable "virtual_network_type" {
  description = "None, External, or Internal."
  type        = string
  default     = "None"
  validation {
    condition     = contains(["External", "Internal", "None"], var.virtual_network_type)
    error_message = "virtual_network_type must be External, Internal, or None."
  }
}
variable "virtual_network_configuration" {
  description = "Subnet for VNet integration. Required when virtual_network_type != None."
  type = object({
    subnet_id = string
  })
  default = null
}
variable "identity" {
  description = "Optional managed identity."
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}
variable "security" {
  description = "Optional TLS/cipher hardening overrides. Defaults disable SSL3/TLS1.0/TLS1.1 on both frontend and backend."
  type = object({
    backend_ssl30_enabled                               = optional(bool)
    backend_tls10_enabled                               = optional(bool)
    backend_tls11_enabled                               = optional(bool)
    frontend_ssl30_enabled                              = optional(bool)
    frontend_tls10_enabled                              = optional(bool)
    frontend_tls11_enabled                              = optional(bool)
    tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled = optional(bool)
  })
  default = null
}
variable "protocols" {
  description = "Optional protocol settings. http2 defaults on."
  type = object({
    http2_enabled = optional(bool)
  })
  default = null
}
variable "sign_in" {
  description = "Optional developer-portal sign-in settings."
  type = object({
    enabled = bool
  })
  default = null
}
variable "sign_up" {
  description = "Optional developer-portal sign-up settings."
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
  description = "Tags applied to the service."
  type        = map(string)
  default     = {}
}

variable "min_api_version" {
  description = "Pin the control-plane API version the service accepts (e.g. 2021-08-01)."
  type        = string
  default     = null
}

variable "client_certificate_enabled" {
  description = "Require a client certificate on the gateway (Consumption tier only)."
  type        = bool
  default     = null
}

variable "zones" {
  description = "Availability zones for the service (Premium tier). null lets Azure choose."
  type        = list(string)
  default     = null
}

variable "timeouts" {
  description = "Optional resource operation timeouts. APIM create/update can take 45+ minutes."
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = {}
}
