variable "container_name" {
  type        = string
  description = "Name of the container resource group"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Specify the supported Azure location where the resource exists."
}

variable "container_sku" {
  type        = string
  description = "Specifies the sku of the container group. Allowed values `Confidential`, `Dedicated` and `Standard`."
  default     = "Standard"
}

variable "os_type" {
  type        = string
  description = "The OS for the container group. Allowed values are `Linux` and `Windows`."
  default     = "Linux"
}

variable "ip_address_type" {
  type        = string
  description = "Specifies the IP address type of the container. Allowed values `Public`, `Private` and `None`."
  default     = "Private"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet resource IDs for a container group."
}

variable "dns_config" {
  type = map(object({
    nameservers    = list(string)
    search_domains = optional(list(string))
  }))
  description = "DNS config to set custom DNS server information."
}

variable "container_info" {
  type = map(object({
    name                         = string
    image                        = string
    cpu                          = number
    memory                       = number
    environment_variables        = optional(map(any))
    secure_environment_variables = optional(map(any))
    ports                        = optional(map(object({
      port = number
      protocol = string
    })))
  }))
  description = "Configuration for the container to be created."
}

variable "restart_policy" {
  type        = string
  description = "Restart policy for the container group. Allowed values are `Always`, `Never`, `OnFailure`"
  default     = "Always"
}