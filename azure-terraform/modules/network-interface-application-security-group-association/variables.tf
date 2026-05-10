variable "associations" {
  type = map(object({
    network_interface_id          = string
    application_security_group_id = string
  }))
  default = {}
}
