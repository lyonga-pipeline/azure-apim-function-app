variable "route_table_name" {
  description = "Name of Vnet peering"
  type        = string
}

variable "location" {
  type        = string
  description = "The location/region where the route table is created."
}

variable "resource_group_name" {
  description = "Resource Group name for the resource"
  type        = string
}

variable "subnet_ids" {
  description = "List of Subnet IDs to associate Route Table"
  type        = list(string)
}

variable "routes" {
  type        = list(map(string))
  description = "List of objects that represent the configuration of each route."
  /*ROUTES = [{ name = "", address_prefix = "", next_hop_type = "", next_hop_in_ip_address = "" }]*/
}

variable "bgp_route_propagation_enabled" {
  type        = bool
  description = "Boolean flag which controls propagation of routes learned by BGP on that route table."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the resource."
}