variable "apim_name" {
  description = "The name of the API Management Service. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group in which the API Management Service should be exist. Changing this forces a new resource to be created."
  type        = string
}

variable "api_name" {
  description = "The name of the API Management Service. Changing this forces a new resource to be created."
  type        = string
}

variable "revision" {
  description = "The Revision which used for this API. Changing this forces a new resource to be created."
  type        = string
}

variable "api_type" {
  description = "Type of API. Possible values are graphql, http, soap, and websocket. Defaults to http."
  type        = string
  default     = null
}

variable "display_name" {
  description = "The display name of the API."
  default     = null
  type        = string
}

variable "path" {
  description = "The Path for this API Management API, which is a relative URL which uniquely identifies this API and all of its resource paths within the API Management Service."
  type        = string
  default     = null
}

variable "protocols" {
  description = "A list of protocols the operations in this API can be invoked. Possible values are http, https, ws, and wss."
  type        = set(string)
  default     = null
}

variable "description" {
  description = "A description of the API Management API, which may include HTML formatting tags."
  type        = string
  default     = null
}

variable "contact" {
  description = "A contact block as documented below."
  type = object({
    email = optional(string)
    name  = optional(string)
    url   = optional(string)
  })
  default = null
}

variable "import" {
  description = "A import block as documented below."
  type = object({
    content_format = string
    content_value  = string
    wsdl_selector = optional(object({
      service_name  = string
      endpoint_name = string
    }))
  })
  default = null
}

variable "license" {
  description = "A license block as documented below."
  type = object({
    name = optional(string)
    url  = optional(string)
  })
  default = null
}

variable "oauth2_authorization" {
  description = "A oauth2_authorization block as documented below."
  type = object({
    authorization_server_name = optional(string)
    scope                     = optional(string)
  })
  default = null
}

variable "openid_authentication" {
  description = "A openid_authentication block as documented below."
  type = object({
    openid_provider_name         = optional(string)
    bearer_token_sending_methods = list(string)
  })
  default = null
}

variable "subscription_key_parameter_names" {
  description = "A subscription_key_parameter_names block as documented below."
  type = object({
    header = string
    query  = string
  })
  default = null
}

variable "service_url" {
  description = "Absolute URL of the backend service implementing this API."
  type        = string
  default     = null
}

variable "subscription_required" {
  description = "Should this API require a subscription key? Defaults to true."
  type        = bool
  default     = true
}

variable "terms_of_service_url" {
  description = "Absolute URL of the Terms of Service for the API."
  type        = string
  default     = null
}

variable "api_version" {
  description = "The Version number of this API, if this API is versioned."
  type        = string
  default     = null
}

variable "version_set_id" {
  description = "The ID of the Version Set which this API is associated with."
  type        = string
  default     = null
}

variable "revision_description" {
  description = "The description of the API Revision of the API Management API."
  type        = string
  default     = null
}

variable "version_description" {
  description = "The description of the API Version of the API Management API."
  type        = string
  default     = null
}

variable "source_api_id" {
  description = "The API id of the source API, which could be in format azurerm_api_management_api.example.id or in format azurerm_api_management_api.example.id;rev=1"
  type        = string
  default     = null
}
