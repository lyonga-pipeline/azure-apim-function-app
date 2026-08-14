resource "azurerm_container_group" "container" {
  name                = var.container_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  ip_address_type     = var.ip_address_type
  subnet_ids          = var.ip_address_type == "Private" ? var.subnet_ids : []

  dynamic "container" {
    for_each = var.container_info
    content {
      name                         = container.value.name
      image                        = container.value.image
      cpu                          = container.value.cpu
      memory                       = container.value.memory
      environment_variables        = container.value.environment_variables
      secure_environment_variables = container.value.secure_environment_variables

      dynamic "ports" {
        for_each = container.value.ports

        content {
          port     = ports.value.port
          protocol = ports.value.protocol
        }
      }
    }
  }

  dynamic "dns_config" {
    for_each = var.dns_config

    content {
      nameservers    = dns_config.value.nameservers
      search_domains = dns_config.value.search_domains
    }
  }
}