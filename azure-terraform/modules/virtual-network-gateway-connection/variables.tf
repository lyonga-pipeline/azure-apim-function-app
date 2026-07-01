variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "type" {
  type    = string
  default = "ExpressRoute"
}
variable "virtual_network_gateway_id" { type = string }
variable "express_route_circuit_id" { type = string }
variable "authorization_key" {
  type    = string
  default = null
}
variable "routing_weight" {
  type    = number
  default = 0
}
variable "tags" {
  type    = map(string)
  default = {}
}
