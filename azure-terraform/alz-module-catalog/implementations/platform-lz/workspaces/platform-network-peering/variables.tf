variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the hub and spoke providers."
  type        = string
}

variable "hub_subscription_id" {
  description = "Connectivity subscription ID that contains the hub VNet and Private DNS zones."
  type        = string
}

variable "spoke_subscription_id" {
  description = "Workload subscription ID that contains the spoke VNet."
  type        = string
}

variable "network_peering" {
  description = "Network peering workspace configuration."
  type        = any
  default = {
    enabled = false
  }
}
