resource "azurerm_key_vault_key" "this" {
  for_each        = var.keys
  name            = each.key
  key_vault_id    = var.key_vault_id
  key_type        = each.value.key_type
  key_size        = try(each.value.key_size, null)
  curve           = try(each.value.curve, null)
  key_opts        = each.value.key_opts
  not_before_date = try(each.value.not_before_date, null)
  expiration_date = try(each.value.expiration_date, null)
  tags            = merge(var.tags, try(each.value.tags, {}))

  dynamic "rotation_policy" {
    for_each = try(each.value.rotation_policy, null) == null ? [] : [each.value.rotation_policy]
    content {
      expire_after         = try(rotation_policy.value.expire_after, null)
      notify_before_expiry = try(rotation_policy.value.notify_before_expiry, null)

      dynamic "automatic" {
        for_each = try(rotation_policy.value.automatic, null) == null ? [] : [rotation_policy.value.automatic]
        content {
          time_after_creation = try(automatic.value.time_after_creation, null)
          time_before_expiry  = try(automatic.value.time_before_expiry, null)
        }
      }
    }
  }
}
