resource "azurerm_network_interface" "nic" {
  name                           = local.nic_name
  resource_group_name            = var.resource_group_name
  location                       = var.resource_group_location
  dns_servers                    = var.dns_servers
  ip_forwarding_enabled          = var.ip_forwarding_enabled
  accelerated_networking_enabled = var.accelerated_networking_enabled
  internal_dns_name_label        = var.internal_dns_name_label
  tags                           = merge({ "ResourceName" = local.nic_name }, var.tags)

  ip_configuration {
    name                          = local.ipconfig_name
    primary                       = true
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation_type
    private_ip_address            = var.private_ip_address_allocation_type == "Static" ? element(concat(var.private_ip_address, [""]), 0) : null
  }

  # Avoids triggering recreation of the resource.
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
