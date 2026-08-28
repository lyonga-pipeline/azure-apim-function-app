variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }

variable "sku" {
  type    = string
  default = "Standard"
}

variable "sku_tier" {
  type    = string
  default = null
}

variable "edge_zone" {
  type    = string
  default = null
}

variable "frontend_ip_configurations" {
  type = map(object({
    subnet_id                                          = optional(string)
    private_ip_address                                 = optional(string)
    private_ip_address_allocation                      = optional(string)
    private_ip_address_version                         = optional(string)
    public_ip_address_id                               = optional(string)
    public_ip_prefix_id                                = optional(string)
    gateway_load_balancer_frontend_ip_configuration_id = optional(string)
    zones                                              = optional(set(string))
  }))
}

variable "backend_address_pools" {
  type = map(object({
    virtual_network_id = optional(string)
    synchronous_mode   = optional(string)
    tunnel_interfaces = optional(map(object({
      identifier = number
      type       = string
      protocol   = string
      port       = number
    })), {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  default = {}
}

variable "backend_addresses" {
  type = map(object({
    backend_address_pool_name           = optional(string)
    backend_address_pool_id             = optional(string)
    virtual_network_id                  = optional(string)
    ip_address                          = optional(string)
    backend_address_ip_configuration_id = optional(string)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  default = {}
}

variable "probes" {
  type = map(object({
    protocol            = string
    port                = number
    request_path        = optional(string)
    interval_in_seconds = optional(number, 5)
    number_of_probes    = optional(number, 2)
    probe_threshold     = optional(number)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  default = {}
}

variable "rules" {
  type = map(object({
    protocol                       = string
    frontend_port                  = number
    backend_port                   = number
    frontend_ip_configuration_name = string
    backend_address_pool_names     = optional(list(string), [])
    backend_address_pool_ids       = optional(list(string), [])
    probe_name                     = optional(string)
    probe_id                       = optional(string)
    load_distribution              = optional(string, "Default")
    disable_outbound_snat          = optional(bool, false)
    idle_timeout_in_minutes        = optional(number, 4)
    enable_floating_ip             = optional(bool)
    floating_ip_enabled            = optional(bool)
    tcp_reset_enabled              = optional(bool)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  default = {}
}

variable "nat_rules" {
  type = map(object({
    protocol                       = string
    frontend_ip_configuration_name = string
    backend_port                   = number
    backend_address_pool_name      = optional(string)
    backend_address_pool_id        = optional(string)
    frontend_port                  = optional(number)
    frontend_port_start            = optional(number)
    frontend_port_end              = optional(number)
    idle_timeout_in_minutes        = optional(number)
    enable_floating_ip             = optional(bool)
    floating_ip_enabled            = optional(bool)
    tcp_reset_enabled              = optional(bool)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  default = {}
}

variable "outbound_rules" {
  type = map(object({
    protocol                        = string
    backend_address_pool_name       = optional(string)
    backend_address_pool_id         = optional(string)
    frontend_ip_configuration_names = list(string)
    allocated_outbound_ports        = optional(number)
    idle_timeout_in_minutes         = optional(number)
    tcp_reset_enabled               = optional(bool)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  default = {}
}

variable "timeouts" {
  type = object({
    create = optional(string)
    update = optional(string)
    read   = optional(string)
    delete = optional(string)
  })
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
