variable "name" {
  description = "Name of the App Service Environment v3. Changing this forces a new resource."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the ASE is created in. Changing this forces a new resource."
  type        = string
}

variable "subnet_id" {
  description = "ID of the caller-owned subnet (>= /24, delegated to Microsoft.Web/hostingEnvironments) the ASE connects to. Changing this forces a new resource."
  type        = string
}

variable "internal_load_balancing_mode" {
  description = "Which endpoints to serve internally in the VNet."
  type        = string
  default     = null

  validation {
    condition     = var.internal_load_balancing_mode == null ? true : contains(["None", "Web, Publishing"], var.internal_load_balancing_mode)
    error_message = "internal_load_balancing_mode must be 'None' or 'Web, Publishing'."
  }
}

variable "allow_new_private_endpoint_connections" {
  description = "Whether new Private Endpoint connections to the ASE are allowed."
  type        = bool
  default     = null
}

variable "zone_redundant" {
  description = "Deploy the ASE zone-redundant (provisions additional hosts at extra cost). Changing this forces a new resource."
  type        = bool
  default     = false
}

variable "cluster_settings" {
  description = "Cluster settings keyed by setting name, e.g. { FrontEndSSLCipherSuiteOrder = \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\" }."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to the ASE."
  type        = map(string)
  default     = {}
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
