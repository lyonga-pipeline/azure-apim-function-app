variable "hub_subscription_id" {
  description = "Subscription ID for the Hub"
  type        = string
}

variable "spoke_subscription_id" {
  description = "Subscription ID for the Spoke"
  type        = string
}

variable "hub_rg_name" {
  description = "Resource Group name for the Hub"
  type        = string
}

variable "spoke_rg_name" {
  description = "Resource Group name for the Spoke"
  type        = string
}

variable "hub_vnet_name" {
  description = "Virtual Network name for the Hub"
  type        = string
}

variable "spoke_vnet_name" {
  description = "Virtual Network name for the Spoke"
  type        = string
}