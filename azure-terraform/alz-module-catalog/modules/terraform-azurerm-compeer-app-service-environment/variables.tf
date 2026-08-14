/*
Common Variables
*/
variable "create_v3" {
  description = "Boolean to determine whether to create ASE v3.?"
  type        = bool
  default     = false
}

variable "name" {
  description = "The name of the App Service Environment. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the App Service Environment exists. Defaults to the Resource Group of the Subnet (specified by subnet_id). Changing this forces a new resource to be created."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the Subnet which the App Service Environment should be connected to. Changing this forces a new resource to be created."
  type        = string
}

variable "cluster_setting" {
  description = "Cluster settings for Azure App Service Environment."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

/*
Varibales specific for non V3
*/
variable "internal_load_balancing_mode" {
  description = "Specifies which endpoints to serve internally in the Virtual Network for the App Service Environment."
  type        = string
  default     = null

  validation {
    condition     = var.internal_load_balancing_mode == null ? true : contains(["None", "Web", "Publishing", "Web, Publishing"], var.internal_load_balancing_mode)
    error_message = "The internal_load_balancing_mode must be either 'None', 'Web', 'Publishing', or 'Web, Publishing'."
  }
}

variable "pricing_tier" {
  description = "Pricing tier for the front end instances."
  type        = string
  default     = null

  validation {
    condition     = var.pricing_tier == null ? true : contains(["I1", "I2", "I3"], var.pricing_tier)
    error_message = "The pricing_tier must be either 'I1', 'I2' or 'I3'."
  }
}

variable "front_end_scale_factor" {
  description = "Scale factor for front end instances."
  type        = number
  default     = null

  validation {
    condition     = var.front_end_scale_factor == null ? true : var.front_end_scale_factor >= 5 && var.front_end_scale_factor <= 15
    error_message = "The front_end_scale_factor must be between 5 and 15."
  }
}

variable "allowed_user_ip_cidrs" {
  description = "Allowed user added IP ranges on the ASE database. Use the addresses you want to set as the explicit egress address ranges."
  type        = set(string)
  default     = null
}

/*
Variables specific to V3
*/
variable "allow_new_private_endpoint_connections" {
  description = "Should new Private Endpoint Connections be allowed."
  type        = bool
  default     = null
}

# variable "dedicated_host_count" {
#   description = "This ASEv3 should use dedicated Hosts"
#   type        = number
#   default     = 2
# }

variable "zone_redundant" {
  description = "Set to true to deploy the ASEv3 with availability zones supported. Zonal ASEs can be deployed in some regions. Note: You can only set either dedicated_host_count or zone_redundant but not both. Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

variable "internal_load_balancing_mode_v3" {
  description = "Specifies which endpoints to serve internally in the Virtual Network for the App Service Environment."
  type        = string
  default     = null

  validation {
    condition     = var.internal_load_balancing_mode_v3 == null ? true : contains(["None", "Web, Publishing"], var.internal_load_balancing_mode_v3)
    error_message = "The internal_load_balancing_mode must be either 'None' or 'Web, Publishing'."
  }
}
