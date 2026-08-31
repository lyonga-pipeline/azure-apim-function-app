resource "azurerm_eventgrid_namespace" "main" {
  name                  = var.namespace_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  capacity              = var.capacity
  public_network_access = var.public_network_access
  sku                   = var.sku
  tags                  = var.tags

  identity {
    type         = var.identity_type
    identity_ids = var.identity_ids
  }

  dynamic "inbound_ip_rule" {
    for_each = var.inbound_ip_rules
    content {
      ip_mask = inbound_ip_rule.value.ip_mask
      action  = inbound_ip_rule.value.action
    }
  }

  dynamic "topic_spaces_configuration" {
    for_each = var.topic_spaces_configuration != null ? [var.topic_spaces_configuration] : []
    content {
      alternative_authentication_name_source          = topic_spaces_configuration.value.alternative_authentication_name_source
      maximum_client_sessions_per_authentication_name = topic_spaces_configuration.value.maximum_client_sessions_per_authentication_name
      maximum_session_expiry_in_hours                 = topic_spaces_configuration.value.maximum_session_expiry_in_hours
      route_topic_id                                  = topic_spaces_configuration.value.route_topic_id
    }
  }

}