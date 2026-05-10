resource "azurerm_lb" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  edge_zone           = var.edge_zone
  tags                = var.tags

  dynamic "frontend_ip_configuration" {
    for_each = var.frontend_ip_configurations
    content {
      name                          = frontend_ip_configuration.key
      subnet_id                     = try(frontend_ip_configuration.value.subnet_id, null)
      private_ip_address            = try(frontend_ip_configuration.value.private_ip_address, null)
      private_ip_address_allocation = try(frontend_ip_configuration.value.private_ip_address_allocation, null)
      public_ip_address_id          = try(frontend_ip_configuration.value.public_ip_address_id, null)
      zones                         = try(frontend_ip_configuration.value.zones, null)
    }
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  for_each        = var.backend_address_pools
  name            = each.key
  loadbalancer_id = azurerm_lb.this.id
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
}

resource "azurerm_lb_rule" "this" {
  for_each                       = var.rules
  name                           = each.key
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  backend_address_pool_ids       = [for pool in each.value.backend_address_pool_names : azurerm_lb_backend_address_pool.this[pool].id]
  probe_id                       = try(each.value.probe_name, null) == null ? null : azurerm_lb_probe.this[each.value.probe_name].id
  load_distribution              = try(each.value.load_distribution, "Default")
  disable_outbound_snat          = try(each.value.disable_outbound_snat, false)
  idle_timeout_in_minutes        = try(each.value.idle_timeout_in_minutes, 4)
  enable_floating_ip             = try(each.value.enable_floating_ip, false)
}
