variable "associations" {
  type = map(object({
    network_interface_id    = string
    ip_configuration_name   = string
    backend_address_pool_id = string
  }))
  default = {}
}
