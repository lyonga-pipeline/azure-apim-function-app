variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "ip_configurations" {
  type = map(object({
    subnet_id                                          = string
    private_ip_address_allocation                      = string
    private_ip_address                                 = optional(string)
    primary                                            = optional(bool)
    public_ip_address_id                               = optional(string)
    gateway_load_balancer_frontend_ip_configuration_id = optional(string)
  }))

  validation {
    condition = alltrue([
      for cfg in values(var.ip_configurations) :
      cfg.private_ip_address_allocation == "Dynamic" || try(cfg.private_ip_address, null) != null
    ])
    error_message = "Static IP configurations must set private_ip_address."
  }
}
variable "dns_servers" {
  type    = list(string)
  default = null
}
variable "accelerated_networking_enabled" {
  type    = bool
  default = true
}
variable "ip_forwarding_enabled" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
