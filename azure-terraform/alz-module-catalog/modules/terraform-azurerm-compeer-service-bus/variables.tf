variable "name" {
  description = "The name of the namespace."
  type        = string
}

variable "resource_group_name" {
  description = "The name of an existing resource group that service bus will be provisioned"
  type        = string
}

variable "sku" {
  description = "The SKU of the namespace. The options are: `Basic`, `Standard`, `Premium`."
  type        = string
}

variable "capacity" {
  description = "The number of message units."
  type        = number
  default     = 0
}

variable "topics" {
  type        = any
  default     = []
  description = "List of topics."
}

variable "authorization_rules" {
  type        = any
  default     = []
  description = "List of namespace authorization rules."
}

variable "queues" {
  type        = any
  default     = []
  description = "List of queues."
}

variable "public_network_access_enabled" {
  description = "(Optional) Is public network access enabled for the Service Bus Namespace? Defaults to true."
  type        = bool
}

variable "firewall_ip_rules" {
  description = "Network rules for the Service Bus namespace"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}

variable "enable_identity" {
  type        = bool
  default     = false
  description = "Enable system-assigned managed identity for the Service Bus namespace."
}