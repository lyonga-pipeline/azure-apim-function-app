resource "azurerm_lb" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  sku_tier            = var.sku_tier
  edge_zone           = var.edge_zone
  tags                = var.tags

  dynamic "frontend_ip_configuration" {
    for_each = var.frontend_ip_configurations
    content {
      name                                               = frontend_ip_configuration.key
      subnet_id                                          = try(frontend_ip_configuration.value.subnet_id, null)
      private_ip_address                                 = try(frontend_ip_configuration.value.private_ip_address, null)
      private_ip_address_allocation                      = try(frontend_ip_configuration.value.private_ip_address_allocation, null)
      private_ip_address_version                         = try(frontend_ip_configuration.value.private_ip_address_version, null)
      public_ip_address_id                               = try(frontend_ip_configuration.value.public_ip_address_id, null)
      public_ip_prefix_id                                = try(frontend_ip_configuration.value.public_ip_prefix_id, null)
      gateway_load_balancer_frontend_ip_configuration_id = try(frontend_ip_configuration.value.gateway_load_balancer_frontend_ip_configuration_id, null)
      zones                                              = try(frontend_ip_configuration.value.zones, null)
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  for_each           = var.backend_address_pools
  name               = each.key
  loadbalancer_id    = azurerm_lb.this.id
  virtual_network_id = try(each.value.virtual_network_id, null)
  synchronous_mode   = try(each.value.synchronous_mode, null)

  dynamic "tunnel_interface" {
    for_each = try(each.value.tunnel_interfaces, {})
    content {
      identifier = tunnel_interface.value.identifier
      type       = tunnel_interface.value.type
      protocol   = tunnel_interface.value.protocol
      port       = tunnel_interface.value.port
    }
  }

  timeouts {
    create = try(each.value.timeouts.create, null)
    update = try(each.value.timeouts.update, null)
    read   = try(each.value.timeouts.read, null)
    delete = try(each.value.timeouts.delete, null)
  }
}

resource "azurerm_lb_backend_address_pool_address" "this" {
  for_each = var.backend_addresses

  name                                = each.key
  backend_address_pool_id             = try(each.value.backend_address_pool_id, null) != null ? each.value.backend_address_pool_id : azurerm_lb_backend_address_pool.this[each.value.backend_address_pool_name].id
  virtual_network_id                  = try(each.value.virtual_network_id, null)
  ip_address                          = try(each.value.ip_address, null)
  backend_address_ip_configuration_id = try(each.value.backend_address_ip_configuration_id, null)

  timeouts {
    create = try(each.value.timeouts.create, null)
    update = try(each.value.timeouts.update, null)
    read   = try(each.value.timeouts.read, null)
    delete = try(each.value.timeouts.delete, null)
  }
}

resource "azurerm_lb_probe" "this" {
  for_each            = var.probes
  name                = each.key
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = each.value.protocol
  port                = each.value.port
  request_path        = try(each.value.request_path, null)
  interval_in_seconds = try(each.value.interval_in_seconds, 5)
  number_of_probes    = try(each.value.number_of_probes, 2)
  probe_threshold     = try(each.value.probe_threshold, null)

  timeouts {
    create = try(each.value.timeouts.create, null)
    update = try(each.value.timeouts.update, null)
    read   = try(each.value.timeouts.read, null)
    delete = try(each.value.timeouts.delete, null)
  }
}

resource "azurerm_lb_rule" "this" {
  for_each                       = var.rules
  name                           = each.key
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  backend_address_pool_ids       = length(try(each.value.backend_address_pool_ids, [])) > 0 ? each.value.backend_address_pool_ids : [for pool in try(each.value.backend_address_pool_names, []) : azurerm_lb_backend_address_pool.this[pool].id]
  probe_id                       = try(each.value.probe_id, null) != null ? each.value.probe_id : (try(each.value.probe_name, null) == null ? null : azurerm_lb_probe.this[each.value.probe_name].id)
  load_distribution              = try(each.value.load_distribution, "Default")
  disable_outbound_snat          = try(each.value.disable_outbound_snat, false)
  idle_timeout_in_minutes        = try(each.value.idle_timeout_in_minutes, 4)
  floating_ip_enabled            = try(each.value.floating_ip_enabled, try(each.value.enable_floating_ip, false))
  tcp_reset_enabled              = try(each.value.tcp_reset_enabled, null)

  timeouts {
    create = try(each.value.timeouts.create, null)
    update = try(each.value.timeouts.update, null)
    read   = try(each.value.timeouts.read, null)
    delete = try(each.value.timeouts.delete, null)
  }
}

resource "azurerm_lb_nat_rule" "this" {
  for_each = var.nat_rules

  name                           = each.key
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = each.value.protocol
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  backend_port                   = each.value.backend_port
  backend_address_pool_id        = try(each.value.backend_address_pool_id, null) != null ? each.value.backend_address_pool_id : azurerm_lb_backend_address_pool.this[each.value.backend_address_pool_name].id
  frontend_port                  = try(each.value.frontend_port, null)
  frontend_port_start            = try(each.value.frontend_port_start, null)
  frontend_port_end              = try(each.value.frontend_port_end, null)
  idle_timeout_in_minutes        = try(each.value.idle_timeout_in_minutes, null)
  floating_ip_enabled            = try(each.value.floating_ip_enabled, try(each.value.enable_floating_ip, null))
  tcp_reset_enabled              = try(each.value.tcp_reset_enabled, null)

  timeouts {
    create = try(each.value.timeouts.create, null)
    update = try(each.value.timeouts.update, null)
    read   = try(each.value.timeouts.read, null)
    delete = try(each.value.timeouts.delete, null)
  }
}

resource "azurerm_lb_outbound_rule" "this" {
  for_each = var.outbound_rules

  name                     = each.key
  loadbalancer_id          = azurerm_lb.this.id
  protocol                 = each.value.protocol
  backend_address_pool_id  = try(each.value.backend_address_pool_id, null) != null ? each.value.backend_address_pool_id : azurerm_lb_backend_address_pool.this[each.value.backend_address_pool_name].id
  allocated_outbound_ports = try(each.value.allocated_outbound_ports, null)
  idle_timeout_in_minutes  = try(each.value.idle_timeout_in_minutes, null)
  tcp_reset_enabled        = try(each.value.tcp_reset_enabled, null)

  dynamic "frontend_ip_configuration" {
    for_each = each.value.frontend_ip_configuration_names
    content {
      name = frontend_ip_configuration.value
    }
  }

  timeouts {
    create = try(each.value.timeouts.create, null)
    update = try(each.value.timeouts.update, null)
    read   = try(each.value.timeouts.read, null)
    delete = try(each.value.timeouts.delete, null)
  }
}
