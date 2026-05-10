resource "azurerm_eventgrid_topic" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  input_schema                  = var.input_schema
  public_network_access_enabled = var.public_network_access_enabled
  local_auth_enabled            = var.local_auth_enabled
  tags                          = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "inbound_ip_rule" {
    for_each = var.inbound_ip_rules
    content {
      ip_mask = inbound_ip_rule.value.ip_mask
      action  = try(inbound_ip_rule.value.action, "Allow")
    }
  }
}
