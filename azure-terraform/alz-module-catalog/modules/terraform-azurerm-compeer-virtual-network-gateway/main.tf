resource "azurerm_virtual_network_gateway" "gateway" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = var.type
  vpn_type            = var.vpn_type
  sku                 = var.sku
  active_active       = var.active_active
  bgp_enabled         = coalesce(var.bgp_enabled, var.enable_bgp, true)
  generation          = var.generation
  tags                = var.tags

  dynamic "ip_configuration" {
    for_each = var.ip_configurations
    content {
      name                          = ip_configuration.key
      public_ip_address_id          = ip_configuration.value.public_ip_address_id
      private_ip_address_allocation = try(ip_configuration.value.private_ip_address_allocation, "Dynamic")
      subnet_id                     = ip_configuration.value.subnet_id
    }
  }

  lifecycle {
    precondition {
      condition     = !var.active_active || length(var.ip_configurations) >= 2
      error_message = "active_active gateways require at least two ip_configurations."
    }

    # The gateway type and SKU family must agree. Only the unambiguous
    # mismatches are rejected: Standard and HighPerformance exist for both
    # gateway types, so they are accepted for either.
    precondition {
      condition = var.type != "ExpressRoute" ? true : !contains([
        "Basic",
        "VpnGw1", "VpnGw2", "VpnGw3", "VpnGw4", "VpnGw5",
        "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ",
      ], var.sku)
      error_message = "An ExpressRoute gateway cannot use a VPN SKU (Basic or VpnGw*). Use Standard, HighPerformance, UltraPerformance, ErGwScale, or ErGw1AZ/2AZ/3AZ."
    }

    precondition {
      condition = var.type != "Vpn" ? true : !contains([
        "UltraPerformance", "ErGwScale", "ErGw1AZ", "ErGw2AZ", "ErGw3AZ",
      ], var.sku)
      error_message = "A VPN gateway cannot use an ExpressRoute SKU (UltraPerformance or ErGw*). Use Basic, Standard, HighPerformance, VpnGw1-5, or VpnGw1AZ-5AZ."
    }

    # Documented in azurerm_virtual_network_gateway: a PolicyBased gateway
    # only supports the Basic SKU.
    precondition {
      condition     = !(var.type == "Vpn" && var.vpn_type == "PolicyBased") ? true : var.sku == "Basic"
      error_message = "A PolicyBased VPN gateway only supports the Basic SKU."
    }
  }
}
