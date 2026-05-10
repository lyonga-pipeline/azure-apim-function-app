resource "azurerm_api_management_named_value" "this" {
  for_each = var.named_values

  name                = each.key
  display_name        = each.value.display_name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  value               = try(each.value.value, null)
  secret              = try(each.value.secret, false)
  tags                = try(each.value.tags, null)

  dynamic "value_from_key_vault" {
    for_each = try(each.value.value_from_key_vault, null) == null ? [] : [each.value.value_from_key_vault]
    content {
      secret_id          = value_from_key_vault.value.secret_id
      identity_client_id = try(value_from_key_vault.value.identity_client_id, null)
    }
  }
}
