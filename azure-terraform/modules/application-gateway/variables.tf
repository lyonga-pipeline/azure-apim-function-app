variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "firewall_policy_id" {
  type    = string
  default = null
}
variable "force_firewall_policy_association" {
  type    = bool
  default = false
}
variable "enable_http2" {
  type    = bool
  default = true
}
variable "sku" {
  type = object({
    name     = string
    tier     = string
    capacity = optional(number)
  })
}
variable "autoscale_configuration" {
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = null
}
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}
variable "gateway_ip_configurations" {
  type = map(object({
    subnet_id = string
  }))
}
variable "frontend_ports" {
  type = map(object({
    port = number
  }))
}
variable "frontend_ip_configurations" {
  type = map(object({
    subnet_id                     = optional(string)
    private_ip_address            = optional(string)
    private_ip_address_allocation = optional(string)
    public_ip_address_id          = optional(string)
  }))
}
variable "ssl_policy" {
  type = object({
    policy_type          = string
    policy_name          = optional(string)
    min_protocol_version = optional(string)
    cipher_suites        = optional(list(string))
  })
  default = null
}
variable "ssl_certificates" {
  type = map(object({
    data                = optional(string)
    password            = optional(string)
    key_vault_secret_id = optional(string)
  }))
  default = {}
}
variable "trusted_root_certificates" {
  type = map(object({
    data                = optional(string)
    key_vault_secret_id = optional(string)
  }))
  default = {}
}
variable "trusted_client_certificates" {
  type = map(object({
    data = string
  }))
  default = {}
}
variable "backend_address_pools" {
  type = map(object({
    ip_addresses = optional(list(string))
    fqdns        = optional(list(string))
  }))
  default = {}
}
variable "probes" {
  type = map(object({
    protocol                                  = string
    path                                      = string
    host                                      = optional(string)
    interval                                  = optional(number, 30)
    timeout                                   = optional(number, 30)
    unhealthy_threshold                       = optional(number, 3)
    pick_host_name_from_backend_http_settings = optional(bool)
  }))
  default = {}
}
variable "backend_http_settings" {
  type = map(object({
    port                                = number
    protocol                            = string
    cookie_based_affinity               = optional(string, "Disabled")
    path                                = optional(string)
    request_timeout                     = optional(number, 30)
    host_name                           = optional(string)
    pick_host_name_from_backend_address = optional(bool)
    probe_name                          = optional(string)
    trusted_root_certificate_names      = optional(list(string))
  }))
  default = {}
}
variable "http_listeners" {
  type = map(object({
    frontend_ip_configuration_name = string
    frontend_port_name             = string
    protocol                       = string
    host_name                      = optional(string)
    host_names                     = optional(list(string))
    ssl_certificate_name           = optional(string)
    require_sni                    = optional(bool)
  }))
  default = {}
}
variable "redirect_configurations" {
  type = map(object({
    redirect_type        = string
    target_listener_name = optional(string)
    target_url           = optional(string)
    include_path         = optional(bool)
    include_query_string = optional(bool)
  }))
  default = {}
}
variable "rewrite_rule_sets" {
  type = map(object({
    rewrite_rules = map(object({
      rule_sequence = number
      conditions = optional(map(object({
        variable    = string
        pattern     = string
        ignore_case = optional(bool)
        negate      = optional(bool)
      })), {})
      request_header_configurations = optional(map(object({
        header_name  = string
        header_value = string
      })), {})
      response_header_configurations = optional(map(object({
        header_name  = string
        header_value = string
      })), {})
      url = optional(object({
        components   = optional(string)
        path         = optional(string)
        query_string = optional(string)
        reroute      = optional(bool)
      }))
    }))
  }))
  default = {}
}
variable "url_path_maps" {
  type = map(object({
    default_backend_address_pool_name   = optional(string)
    default_backend_http_settings_name  = optional(string)
    default_redirect_configuration_name = optional(string)
    default_rewrite_rule_set_name       = optional(string)
    path_rules = map(object({
      paths                       = list(string)
      backend_address_pool_name   = optional(string)
      backend_http_settings_name  = optional(string)
      firewall_policy_id          = optional(string)
      redirect_configuration_name = optional(string)
      rewrite_rule_set_name       = optional(string)
    }))
  }))
  default = {}
}
variable "waf_configuration" {
  type = object({
    enabled                  = bool
    firewall_mode            = string
    rule_set_version         = string
    file_upload_limit_mb     = optional(number)
    max_request_body_size_kb = optional(number)
    request_body_check       = optional(bool)
    rule_set_type            = optional(string)
    disabled_rule_groups = optional(map(object({
      rule_group_name = string
      rules           = optional(list(number), [])
    })), {})
    exclusions = optional(map(object({
      match_variable          = string
      selector                = optional(string)
      selector_match_operator = optional(string)
    })), {})
  })
  default = null
}
variable "request_routing_rules" {
  type = map(object({
    rule_type                   = string
    http_listener_name          = string
    backend_address_pool_name   = optional(string)
    backend_http_settings_name  = optional(string)
    redirect_configuration_name = optional(string)
    url_path_map_name           = optional(string)
    rewrite_rule_set_name       = optional(string)
    priority                    = optional(number)
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
