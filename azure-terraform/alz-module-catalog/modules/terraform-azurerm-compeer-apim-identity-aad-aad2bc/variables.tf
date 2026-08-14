variable "create_apim_aad_idp" {
  description = "Whether to create Azure APIM Identity provider AAD"
  type = bool
  default = false
}

variable "create_apim_aadb2c_idp" {
  description = "Whether to create Azure APIM Identity provider AADB2C"
  type = bool
  default = false
}

variable "apim_name" {
  description = "The Name of the API Management Service where this AAD Identity Provider should be created. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The Name of the Resource Group where the API Management Service exists. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "aad_client_id" {
  description = "Client Id of the Application in the AAD Identity Provider."
  type        = string
  default     = null
}

variable "aad_client_secret" {
  description = "Client secret of the Application in the AAD Identity Provider."
  type        = string
  sensitive   = true
  default     = null
}

variable "aad_allowed_tenants" {
  description = "List of allowed AAD Tenants."
  type        = list(string)
  default     = null
}

variable "aad_client_library" {
  description = "The client library to use for the AAD Identity Provider. Possible values are 'MSAL-2' and 'ADAL'."
  type        = string
  default     = "MSAL-2"
}

variable "aad_signin_tenant" {
  description = "The AAD Tenant to use instead of Common when logging into Active Directory"
  type        = string
  default     = null
}

variable "aadb2c_client_id" {
  description = "Client ID of the Application in your B2C tenant."
  type        = string
  default     = null
}

variable "aadb2c_client_secret" {
  description = "Client secret of the Application in your B2C tenant."
  type        = string
  sensitive   = true
  default     = null
}

variable "aadb2c_allowed_tenant" {
  description = "The allowed AAD tenant, usually your B2C tenant domain."
  type        = string
  default     = null
}

variable "aadb2c_signin_tenant" {
  description = "The tenant to use instead of Common when logging into Active Directory, usually your B2C tenant domain."
  type        = string
  default     = null
}

variable "aadb2c_authority" {
  description = "OpenID Connect discovery endpoint hostname, usually your b2clogin.com domain."
  type        = string
  default     = null
}

variable "aadb2c_signin_policy" {
  description = "Signin Policy Name."
  type        = string
  default     = null
}

variable "aadb2c_signup_policy" {
  description = "Signup Policy Name"
  type        = string
  default     = null
}

variable "aadb2c_password_reset_policy" {
  description = "Password reset Policy Name."
  type        = string
  default     = null
}

variable "aadb2c_profile_editing_policy" {
  description = "Profile editing Policy Name."
  type        = string
  default     = null
}