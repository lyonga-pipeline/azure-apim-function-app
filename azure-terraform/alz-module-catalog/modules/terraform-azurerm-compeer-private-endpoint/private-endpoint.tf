resource "azurerm_private_endpoint" "private_endpoint" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  custom_network_interface_name = var.custom_network_interface_name != null ? var.custom_network_interface_name : null
  location                      = var.location
  edge_zone                     = var.edge_zone
  subnet_id                     = var.subnet_id
  tags                          = var.tags
  dynamic "private_service_connection" {
    for_each = local.private_service_connections
    content {
      name                              = private_service_connection.value.name
      is_manual_connection              = private_service_connection.value.is_manual_connection
      private_connection_resource_id    = try(private_service_connection.value.private_connection_resource_id, null)
      subresource_names                 = try(private_service_connection.value.subresource_names, null)
      request_message                   = try(private_service_connection.value.request_message, null)
      private_connection_resource_alias = try(private_service_connection.value.private_connection_resource_alias, null)
    }
  }
  dynamic "private_dns_zone_group" {
    for_each = local.private_dns_zone_groups
    content {
      name                 = private_dns_zone_group.value.name
      private_dns_zone_ids = private_dns_zone_group.value.private_dns_zone_ids
    }
  }
  dynamic "ip_configuration" {
    for_each = local.ip_configurations
    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = ip_configuration.value.subresource_name
      member_name        = ip_configuration.value.member_name
    }
  }

  timeouts {
    create = try(var.timeouts.create, "1h")
    update = try(var.timeouts.update, "1h")
    read   = try(var.timeouts.read, "5m")
    delete = try(var.timeouts.delete, "1h")
  }
}
