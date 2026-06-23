resource "azurerm_private_endpoint" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.subnet_id
  custom_network_interface_name = var.custom_network_interface_name
  tags                          = var.tags

  private_service_connection {
    name                              = coalesce(try(var.private_service_connection.name, null), "${var.name}-psc")
    is_manual_connection              = try(var.private_service_connection.is_manual_connection, false)
    private_connection_resource_id    = try(var.private_service_connection.private_connection_resource_id, null)
    private_connection_resource_alias = try(var.private_service_connection.private_connection_resource_alias, null)
    subresource_names                 = try(var.private_service_connection.subresource_names, null)
    request_message                   = try(var.private_service_connection.request_message, null)
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_group == null ? [] : [var.private_dns_zone_group]
    content {
      name                 = coalesce(try(private_dns_zone_group.value.name, null), "${var.name}-dns")
      private_dns_zone_ids = private_dns_zone_group.value.private_dns_zone_ids
    }
  }

  dynamic "ip_configuration" {
    for_each = var.ip_configurations
    content {
      name               = ip_configuration.key
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = try(ip_configuration.value.subresource_name, null)
      member_name        = try(ip_configuration.value.member_name, null)
    }
  }
}
