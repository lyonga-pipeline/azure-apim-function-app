output "policy_definition_ids" {
  value = {
    allowed_locations          = azurerm_policy_definition.allowed_locations.id
    required_tag               = azurerm_policy_definition.required_tag.id
    deny_public_ip             = azurerm_policy_definition.deny_public_ip.id
    storage_public_network     = azurerm_policy_definition.storage_public_network.id
    key_vault_public_network   = azurerm_policy_definition.key_vault_public_network.id
    sql_public_network         = azurerm_policy_definition.sql_public_network.id
    app_service_public_network = azurerm_policy_definition.app_service_public_network.id
  }
}

output "policy_set_id" {
  value = azurerm_policy_set_definition.landing_zone_baseline.id
}

output "assignment_ids" {
  value = { for key, value in azurerm_management_group_policy_assignment.landing_zone_baseline : key => value.id }
}

