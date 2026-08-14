variable "apim_name" {
  description = "The name of the API Management Service. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group in which the API Management Service should be exist. Changing this forces a new resource to be created."
  type        = string
}

variable "location" {
  description = "The Azure location where the API Management Service exists. Changing this forces a new resource to be created."
  type        = string
}

variable "publisher_name" {
  description = "The name of publisher/company."
  type        = string
}

variable "publisher_email" {
  description = "The email of publisher/company."
  type        = string
}

variable "sku_name" {
  description = "sku_name is a string consisting of two parts separated by an underscore(_). The first part is the name, valid values include: Consumption, Developer, Basic, Standard and Premium. The second part is the capacity (e.g. the number of deployed units of the sku), which must be a positive integer (e.g. Developer_1)."
  type        = string
}

variable "additional_location" {
  description = "One or more additional_location blocks as defined below."
  type = list(object({
    location             = string
    capacity             = optional(number)
    zones                = optional(set(string))
    public_ip_address_id = optional(string)
    gateway_disabled     = optional(bool)
    virtual_network_configuration = optional(object({
      subnet_id = string
    }))
  }))
  default = []
}

variable "certificate" {
  description = "One or more (up to 10) certificate blocks as defined below."
  type = list(object({
    encoded_certificate  = string
    store_name           = string
    certificate_password = optional(string)
  }))
  default = []
}

variable "client_certificate_enabled" {
  description = "Enforce a client certificate to be presented on each request to the gateway? This is only supported when SKU type is Consumption."
  type        = bool
  default     = false
}

variable "delegation" {
  description = "A delegation block as defined below."
  type = object({
    subscriptions_enabled     = optional(bool)
    user_registration_enabled = optional(bool)
    url                       = optional(string)
    validation_key            = optional(string)
  })
  default = null
}

variable "gateway_disabled" {
  description = "Disable the gateway in main region? This is only supported when additional_location is set."
  type        = bool
  default     = null
}

variable "min_api_version" {
  description = "The version which the control plane API calls to API Management service are limited with version equal to or newer than."
  type        = number
  default     = null
}

variable "zones" {
  description = "Specifies a list of Availability Zones in which this API Management service should be located. Changing this forces a new API Management service to be created."
  type        = set(string)
  default     = null
}

variable "identity" {
  description = "An identity block as defined below."
  type = object({
    type         = string
    identity_ids = optional(set(string))
  })
  default = null
}

variable "hostname_configuration" {
  description = "An hostname_configuration block as defined below."
  type = object({
    management = optional(list(object({
      host_name                       = string
      key_vault_id                    = optional(string)
      certificate                     = optional(string)
      certificate_password            = optional(string)
      negotiate_client_certificate    = optional(bool)
      ssl_keyvault_identity_client_id = optional(string)
    })))
    portal = optional(list(object({
      host_name                       = string
      key_vault_id                    = optional(string)
      certificate                     = optional(string)
      certificate_password            = optional(string)
      negotiate_client_certificate    = optional(bool)
      ssl_keyvault_identity_client_id = optional(string)
    })))
    developer_portal = optional(list(object({
      host_name                       = string
      key_vault_id                    = optional(string)
      certificate                     = optional(string)
      certificate_password            = optional(string)
      negotiate_client_certificate    = optional(bool)
      ssl_keyvault_identity_client_id = optional(string)
    })))
    proxy = optional(list(object({
      host_name                       = string
      key_vault_id                    = optional(string)
      certificate                     = optional(string)
      certificate_password            = optional(string)
      negotiate_client_certificate    = optional(bool)
      ssl_keyvault_identity_client_id = optional(string)
    })))
    scm = optional(list(object({
      host_name                       = string
      key_vault_id                    = optional(string)
      certificate                     = optional(string)
      certificate_password            = optional(string)
      negotiate_client_certificate    = optional(bool)
      ssl_keyvault_identity_client_id = optional(string)
    })))
  })
  default = null
}

variable "notification_sender_email" {
  description = "Email address from which the notification will be sent."
  type        = string
  default     = null
}

variable "policy" {
  description = "An policy block as defined below."
  type = object({
    xml_content = optional(string)
    xml_link    = optional(string)
  })
  default = null
}

variable "protocols" {
  description = "An protocols block as defined below."
  type = object({
    enable_http2 = bool
  })
  default = null
}

variable "security" {
  description = "An security block as defined below."
  type = object({
    enable_backend_ssl30                                = optional(bool)
    enable_backend_tls10                                = optional(bool)
    enable_backend_tls11                                = optional(bool)
    enable_frontend_ssl30                               = optional(bool)
    enable_frontend_tls10                               = optional(bool)
    enable_frontend_tls11                               = optional(bool)
    tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled = optional(bool)
    tls_ecdhe_ecdsa_with_aes256_cbc_sha_ciphers_enabled = optional(bool)
    tls_ecdhe_rsa_with_aes128_cbc_sha_ciphers_enabled   = optional(bool)
    tls_ecdhe_rsa_with_aes256_cbc_sha_ciphers_enabled   = optional(bool)
    tls_rsa_with_aes128_cbc_sha256_ciphers_enabled      = optional(bool)
    tls_rsa_with_aes128_cbc_sha_ciphers_enabled         = optional(bool)
    tls_rsa_with_aes128_gcm_sha256_ciphers_enabled      = optional(bool)
    tls_rsa_with_aes256_gcm_sha384_ciphers_enabled      = optional(bool)
    tls_rsa_with_aes256_cbc_sha256_ciphers_enabled      = optional(bool)
    tls_rsa_with_aes256_cbc_sha_ciphers_enabled         = optional(bool)
    triple_des_ciphers_enabled                          = optional(bool)
  })
  default = null
}

variable "sign_in" {
  description = "An sign_in block as defined below."
  type = object({
    enabled = bool
  })
  default = null
}

variable "sign_up" {
  description = "An sign_up block as defined below."
  type = object({
    enabled = bool
    terms_of_service = object({
      consent_required = bool
      enabled          = bool
      text             = string
    })
  })
  default = null
}

variable "tenant_access" {
  description = "An tenant_access block as defined below."
  type = object({
    enabled = bool
  })
  default = null
}

variable "public_ip_address_id" {
  description = "ID of a standard SKU IPv4 Public IP."
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Is public access to the service allowed?"
  type        = bool
  default     = true
}

variable "virtual_network_type" {
  description = "The type of virtual network you want to use, valid values include: None, External, Internal."
  type        = string
  default     = "Internal"
}

variable "virtual_network_configuration" {
  description = "A virtual_network_configuration block as defined below. Required when virtual_network_type is External or Internal."
  type = object({
    subnet_id = string
  })
  default = null
}

variable "tags" {
  description = "A mapping of tags assigned to the resource."
  type        = map(string)
  default     = {}
}

variable "diagnostic_setting_name" {
  description = "Name for the diagnostic settings"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Specifices the ID of the Log Analytics Workspace where Diagnostic Data should be sent"
  type        = string
}

variable "log_analytics_destination_type" {
  description = "When set to 'Dedicated' logs sent to Log Analytics workspace will go into resource specific tables, instead of the legacy AzureDiagnostics table"
  type        = string
  default     = "AzureDiagnostics"
}