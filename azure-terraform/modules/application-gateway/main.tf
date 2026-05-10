resource "azurerm_application_gateway" "this" {
  name                              = var.name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  firewall_policy_id                = var.firewall_policy_id
  force_firewall_policy_association = var.force_firewall_policy_association
  enable_http2                      = var.enable_http2
  tags                              = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = try(var.sku.capacity, null)
  }

  dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration == null ? [] : [var.autoscale_configuration]
    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = autoscale_configuration.value.max_capacity
    }
  }

  dynamic "gateway_ip_configuration" {
    for_each = var.gateway_ip_configurations
    content {
      name      = gateway_ip_configuration.key
      subnet_id = gateway_ip_configuration.value.subnet_id
    }
  }

  dynamic "frontend_port" {
    for_each = var.frontend_ports
    content {
      name = frontend_port.key
      port = frontend_port.value.port
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.frontend_ip_configurations
    content {
      name                          = frontend_ip_configuration.key
      subnet_id                     = try(frontend_ip_configuration.value.subnet_id, null)
      private_ip_address            = try(frontend_ip_configuration.value.private_ip_address, null)
      private_ip_address_allocation = try(frontend_ip_configuration.value.private_ip_address_allocation, null)
      public_ip_address_id          = try(frontend_ip_configuration.value.public_ip_address_id, null)
    }
  }

  dynamic "ssl_policy" {
    for_each = var.ssl_policy == null ? [] : [var.ssl_policy]
    content {
      policy_type          = ssl_policy.value.policy_type
      policy_name          = try(ssl_policy.value.policy_name, null)
      min_protocol_version = try(ssl_policy.value.min_protocol_version, null)
      cipher_suites        = try(ssl_policy.value.cipher_suites, null)
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.key
      data                = try(ssl_certificate.value.data, null)
      password            = try(ssl_certificate.value.password, null)
      key_vault_secret_id = try(ssl_certificate.value.key_vault_secret_id, null)
    }
  }

  dynamic "trusted_root_certificate" {
    for_each = var.trusted_root_certificates
    content {
      name                = trusted_root_certificate.key
      data                = try(trusted_root_certificate.value.data, null)
      key_vault_secret_id = try(trusted_root_certificate.value.key_vault_secret_id, null)
    }
  }

  dynamic "trusted_client_certificate" {
    for_each = var.trusted_client_certificates
    content {
      name = trusted_client_certificate.key
      data = trusted_client_certificate.value.data
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.key
      ip_addresses = try(backend_address_pool.value.ip_addresses, null)
      fqdns        = try(backend_address_pool.value.fqdns, null)
    }
  }

  dynamic "probe" {
    for_each = var.probes
    content {
      name                                      = probe.key
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      host                                      = try(probe.value.host, null)
      interval                                  = try(probe.value.interval, 30)
      timeout                                   = try(probe.value.timeout, 30)
      unhealthy_threshold                       = try(probe.value.unhealthy_threshold, 3)
      pick_host_name_from_backend_http_settings = try(probe.value.pick_host_name_from_backend_http_settings, null)
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.key
      cookie_based_affinity               = try(backend_http_settings.value.cookie_based_affinity, "Disabled")
      path                                = try(backend_http_settings.value.path, null)
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      request_timeout                     = try(backend_http_settings.value.request_timeout, 30)
      host_name                           = try(backend_http_settings.value.host_name, null)
      pick_host_name_from_backend_address = try(backend_http_settings.value.pick_host_name_from_backend_address, null)
      probe_name                          = try(backend_http_settings.value.probe_name, null)
      trusted_root_certificate_names      = try(backend_http_settings.value.trusted_root_certificate_names, null)
    }
  }

  dynamic "redirect_configuration" {
    for_each = var.redirect_configurations
    content {
      name                 = redirect_configuration.key
      redirect_type        = redirect_configuration.value.redirect_type
      target_listener_name = try(redirect_configuration.value.target_listener_name, null)
      target_url           = try(redirect_configuration.value.target_url, null)
      include_path         = try(redirect_configuration.value.include_path, null)
      include_query_string = try(redirect_configuration.value.include_query_string, null)
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = var.rewrite_rule_sets
    content {
      name = rewrite_rule_set.key

      dynamic "rewrite_rule" {
        for_each = rewrite_rule_set.value.rewrite_rules
        content {
          name          = rewrite_rule.key
          rule_sequence = rewrite_rule.value.rule_sequence

          dynamic "condition" {
            for_each = try(rewrite_rule.value.conditions, {})
            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = try(condition.value.ignore_case, null)
              negate      = try(condition.value.negate, null)
            }
          }

          dynamic "request_header_configuration" {
            for_each = try(rewrite_rule.value.request_header_configurations, {})
            content {
              header_name  = request_header_configuration.value.header_name
              header_value = request_header_configuration.value.header_value
            }
          }

          dynamic "response_header_configuration" {
            for_each = try(rewrite_rule.value.response_header_configurations, {})
            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }

          dynamic "url" {
            for_each = try(rewrite_rule.value.url, null) == null ? [] : [rewrite_rule.value.url]
            content {
              components   = try(url.value.components, null)
              path         = try(url.value.path, null)
              query_string = try(url.value.query_string, null)
              reroute      = try(url.value.reroute, null)
            }
          }
        }
      }
    }
  }

  dynamic "url_path_map" {
    for_each = var.url_path_maps
    content {
      name                                = url_path_map.key
      default_backend_address_pool_name   = try(url_path_map.value.default_backend_address_pool_name, null)
      default_backend_http_settings_name  = try(url_path_map.value.default_backend_http_settings_name, null)
      default_redirect_configuration_name = try(url_path_map.value.default_redirect_configuration_name, null)
      default_rewrite_rule_set_name       = try(url_path_map.value.default_rewrite_rule_set_name, null)

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules
        content {
          name                        = path_rule.key
          paths                       = path_rule.value.paths
          backend_address_pool_name   = try(path_rule.value.backend_address_pool_name, null)
          backend_http_settings_name  = try(path_rule.value.backend_http_settings_name, null)
          firewall_policy_id          = try(path_rule.value.firewall_policy_id, null)
          redirect_configuration_name = try(path_rule.value.redirect_configuration_name, null)
          rewrite_rule_set_name       = try(path_rule.value.rewrite_rule_set_name, null)
        }
      }
    }
  }

  dynamic "waf_configuration" {
    for_each = var.waf_configuration == null ? [] : [var.waf_configuration]
    content {
      enabled                  = waf_configuration.value.enabled
      firewall_mode            = waf_configuration.value.firewall_mode
      rule_set_version         = waf_configuration.value.rule_set_version
      file_upload_limit_mb     = try(waf_configuration.value.file_upload_limit_mb, null)
      max_request_body_size_kb = try(waf_configuration.value.max_request_body_size_kb, null)
      request_body_check       = try(waf_configuration.value.request_body_check, null)
      rule_set_type            = try(waf_configuration.value.rule_set_type, null)

      dynamic "disabled_rule_group" {
        for_each = try(waf_configuration.value.disabled_rule_groups, {})
        content {
          rule_group_name = disabled_rule_group.value.rule_group_name
          rules           = try(disabled_rule_group.value.rules, [])
        }
      }

      dynamic "exclusion" {
        for_each = try(waf_configuration.value.exclusions, {})
        content {
          match_variable          = exclusion.value.match_variable
          selector                = try(exclusion.value.selector, null)
          selector_match_operator = try(exclusion.value.selector_match_operator, null)
        }
      }
    }
  }

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.key
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_name                      = try(http_listener.value.host_name, null)
      host_names                     = try(http_listener.value.host_names, null)
      ssl_certificate_name           = try(http_listener.value.ssl_certificate_name, null)
      require_sni                    = try(http_listener.value.require_sni, null)
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                        = request_routing_rule.key
      rule_type                   = request_routing_rule.value.rule_type
      http_listener_name          = request_routing_rule.value.http_listener_name
      backend_address_pool_name   = try(request_routing_rule.value.backend_address_pool_name, null)
      backend_http_settings_name  = try(request_routing_rule.value.backend_http_settings_name, null)
      redirect_configuration_name = try(request_routing_rule.value.redirect_configuration_name, null)
      url_path_map_name           = try(request_routing_rule.value.url_path_map_name, null)
      rewrite_rule_set_name       = try(request_routing_rule.value.rewrite_rule_set_name, null)
      priority                    = try(request_routing_rule.value.priority, null)
    }
  }
}
