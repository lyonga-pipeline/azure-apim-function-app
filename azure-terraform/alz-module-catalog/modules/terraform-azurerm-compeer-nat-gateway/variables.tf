variable "nat_gateway_name" {
  description = "Name of the NAT Gateway"
  type        = string
}

variable "public_ip_name" {
  description = "Name of the public_ip_name"
  type        = string
}

variable "location" {
  description = "The Azure region where the NAT Gateway should exist."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the NAT Gateway should exist."
  type        = string
}

variable "sku_name" {
  description = "SKU of the NAT Gateway"
  type        = string
  default     = "Standard"
}

variable "public_ip_count" {
  description = "Number of public IPs to associate with NAT Gateway"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate with NAT Gateway"
  type        = list(string)
}

// variable "availability_zones" {
//   description = "Availability Zones for the NAT Gateway and Public IPs"
//   type        = list(string)
//   default     = ["1", "2", "3"]
// }

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
  default     = {}
}

###
