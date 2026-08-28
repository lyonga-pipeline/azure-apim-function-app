locals {
  private_service_connections = {
    for connection in var.private_service_connections : connection.name => connection
  }

  private_dns_zone_groups = {
    for zone_group in var.private_dns_zone_group : zone_group.name => zone_group
  }

  ip_configurations = {
    for configuration in var.ip_configurations : configuration.name => configuration
  }
}
