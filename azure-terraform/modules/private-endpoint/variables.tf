variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subnet_id" { type = string }
variable "custom_network_interface_name" {
  type    = string
  default = null
}
variable "private_service_connection" {
  type = object({
    name                              = optional(string)
    private_connection_resource_id    = optional(string)
    private_connection_resource_alias = optional(string)
    subresource_names                 = optional(list(string))
    is_manual_connection              = optional(bool, false)
    request_message                   = optional(string)
  })

  validation {
    condition = (
      (
        try(var.private_service_connection.private_connection_resource_id, null) != null ||
        try(var.private_service_connection.private_connection_resource_alias, null) != null
      ) &&
      !(
        try(var.private_service_connection.private_connection_resource_id, null) != null &&
        try(var.private_service_connection.private_connection_resource_alias, null) != null
      )
    )
    error_message = "private_service_connection must set exactly one of private_connection_resource_id or private_connection_resource_alias."
  }
}
variable "private_dns_zone_group" {
  type = object({
    name                 = optional(string)
    private_dns_zone_ids = list(string)
  })
  default = null
}
variable "ip_configurations" {
  type = map(object({
    private_ip_address = string
    subresource_name   = optional(string)
    member_name        = optional(string)
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
