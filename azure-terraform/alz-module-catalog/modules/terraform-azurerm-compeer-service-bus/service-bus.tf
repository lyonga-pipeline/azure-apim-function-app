resource "azurerm_servicebus_namespace" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  capacity                      = var.capacity
  premium_messaging_partitions  = var.premium_messaging_partitions
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled
  local_auth_enabled            = var.local_auth_enabled
  tags                          = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(length(identity.value.identity_ids), 0) == 0 ? null : identity.value.identity_ids
    }
  }

  dynamic "network_rule_set" {
    for_each = var.network_rule_set == null ? [] : [var.network_rule_set]
    content {
      default_action                = network_rule_set.value.default_action
      public_network_access_enabled = try(network_rule_set.value.public_network_access_enabled, var.public_network_access_enabled)
      trusted_services_allowed      = try(network_rule_set.value.trusted_services_allowed, false)
      ip_rules                      = try(network_rule_set.value.ip_rules, [])
      dynamic "network_rules" {
        for_each = try(network_rule_set.value.network_rules, {})
        content {
          subnet_id                            = network_rules.value.subnet_id
          ignore_missing_vnet_service_endpoint = try(network_rules.value.ignore_missing_vnet_service_endpoint, false)
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.sku == "Premium" || (var.capacity == 0 && var.premium_messaging_partitions == 0)
      error_message = "capacity and premium_messaging_partitions are Premium SKU settings."
    }
    precondition {
      condition     = var.identity == null ? true : (!strcontains(var.identity.type, "UserAssigned") || length(try(var.identity.identity_ids, [])) > 0)
      error_message = "identity_ids must be supplied when identity.type includes UserAssigned."
    }
  }
}
