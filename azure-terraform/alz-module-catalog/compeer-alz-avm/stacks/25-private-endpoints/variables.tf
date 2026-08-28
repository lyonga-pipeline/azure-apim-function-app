variable "subscription_id" { type = string }
variable "location" {
  type    = string
  default = "centralus"
}

variable "enable_telemetry" {
  type    = bool
  default = true
}
variable "endpoints" {
  type = map(object({
    name                           = string
    network_interface_name         = string
    resource_group_name            = string
    subnet_resource_id             = string
    private_connection_resource_id = string
    subresource_names              = list(string)
    private_dns_zone_resource_ids  = list(string)
    private_ip_address             = optional(string)
    tags                           = optional(map(string), {})
  }))
}
