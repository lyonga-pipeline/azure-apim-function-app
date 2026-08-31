variable "apim_name" {
  description = "Name of the target API Management service."
  type        = string
}
variable "resource_group_name" {
  description = "Resource group containing the API Management service."
  type        = string
}

variable "aad" {
  description = "Optional Azure AD identity-provider configuration. Null means this provider is not managed."
  type = object({
    client_id       = string
    client_secret   = string
    allowed_tenants = list(string)
    client_library  = optional(string, "MSAL-2")
    signin_tenant   = optional(string)
  })
  default = null
}

variable "aadb2c" {
  description = "Optional Azure AD B2C identity-provider configuration. Null means this provider is not managed."
  type = object({
    client_id              = string
    client_secret          = string
    allowed_tenant         = string
    signin_tenant          = string
    authority              = string
    signin_policy          = string
    signup_policy          = optional(string)
    password_reset_policy  = optional(string)
    profile_editing_policy = optional(string)
  })
  default = null
}
