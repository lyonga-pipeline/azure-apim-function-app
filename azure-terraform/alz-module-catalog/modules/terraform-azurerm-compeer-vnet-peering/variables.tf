variable "peering_name" {
  description = "Name of Vnet peering"
  type        = string
}

variable "rg_name" {
  description = "Resource Group name for the resource"
  type        = string
}

variable "vnet_name" {
  description = "Virtual Network name for the resource"
  type        = string
}

variable "remote_virtual_network_id" {
  description = "The full Azure resource ID of the remote virtual network. Changing this forces a new resource to be created."
  type        = string
}


variable "allow_virtual_network_access" {
  description = "Option allow_virtual_network_access for the vnet to peer. Controls if the VMs in the remote virtual network can access VMs in the local virtual network. Defaults to false. https://www.terraform.io/docs/providers/azurerm/r/virtual_network_peering.html#allow_virtual_network_access"
  type        = bool
}

variable "allow_forwarded_traffic" {
  description = "Option allow_forwarded_traffic for the vnet to peer. Controls if forwarded traffic from VMs in the remote virtual network is allowed. Defaults to false. https://www.terraform.io/docs/providers/azurerm/r/virtual_network_peering.html#allow_forwarded_traffic"
  type        = bool
}

variable "allow_gateway_transit" {
  description = "Option allow_gateway_transit for the vnet to peer. Controls gatewayLinks can be used in the remote virtual network’s link to the local virtual network. https://www.terraform.io/docs/providers/azurerm/r/virtual_network_peering.html#allow_gateway_transit"
  type        = bool
}

variable "use_remote_gateways" {
  description = "Option use_remote_gateway for the vnet to peer. Controls if remote gateways can be used on the local virtual network. https://www.terraform.io/docs/providers/azurerm/r/virtual_network_peering.html#use_remote_gateways"
  type        = bool
}
