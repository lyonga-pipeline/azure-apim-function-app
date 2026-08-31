variable "apim_name" {
  description = "The Name of the API Management Service where this backend should be created. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "The Name of the Resource Group where the API Management Service exists. Changing this forces a new resource to be created."
  type        = string
}

variable "apim_backend_name" {
  description = "The name of the API Management backend. Changing this forces a new resource to be created."
  type        = string
}

variable "apim_backend_protocol" {
  description = "The protocol used by the backend host. Possible values are http or soap."
  type        = string
}

variable "apim_backend_url" {
  description = "The URL of the backend host."
  type        = string
}

variable "apim_backend_description" {
  description = "The description of the backend."
  default     = null
  type        = string
}

variable "apim_backend_resource_id" {
  description = "The management URI of the backend host in an external system. This URI can be the ARM Resource ID of Logic Apps, Function Apps or API Apps, or the management endpoint of a Service Fabric cluster."
  default     = null
  type        = string
}

variable "apim_backend_title" {
  description = "The title of the backend."
  default     = null
  type        = string
}

variable "credentials" {
  description = "A credentials block as documented below."
  type = object({
    authorization = optional(object({
      parameter = optional(string)
      scheme    = optional(string)
    }))
    certificate = optional(list(string))
    header      = optional(map(string))
    query       = optional(map(string))
  })
  default = null
}

variable "proxy" {
  description = "A proxy block as documented below."
  type = object({
    password = optional(string)
    url      = string
    username = string
  })
  default = null
}

variable "service_fabric_cluster" {
  description = "A service_fabric_cluster block as documented below."
  type = object({
    management_endpoints             = list(string)
    max_partition_resolution_retries = number
    client_certificate_thumbprint    = optional(string)
    client_certificate_id            = optional(string)
    server_certificate_thumbprints   = optional(list(string))
    server_x509_name = optional(object({
      issuer_certificate_thumbprint = string
      name                          = string
    }))
  })
  default = null
}

variable "tls" {
  description = "A tls block as documented below."
  type = object({
    validate_certificate_chain = optional(bool)
    validate_certificate_name  = optional(bool)
  })
  default = null
}
