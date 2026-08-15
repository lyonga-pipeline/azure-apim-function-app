variable "apim_name" {
  description = "The name of the API Management Service in which this OpenID Connect Provider should be created. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the API Management Service exists. Changing this forces a new resource to be created."
  type        = string
}

variable "openid_provider_name" {
  description = "The Name of the OpenID Connect Provider which should be created within the API Management Service. Changing this forces a new resource to be created."
  type        = string
}

variable "client_id" {
  description = "The Client ID used for the Client Application."
  type        = string
}

variable "client_secret" {
  description = "The Client Secret used for the Client Application."
  sensitive   = true
  type        = string
}

variable "display_name" {
  description = "A user-friendly name for this OpenID Connect Provider."
  type        = string
}

variable "metadata_endpoint" {
  description = "The URI of the Metadata endpoint."
  type        = string
}

variable "description" {
  description = "A description of this OpenID Connect Provider."
  type        = string
  default     = null
}