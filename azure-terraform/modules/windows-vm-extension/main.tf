resource "azurerm_virtual_machine_extension" "this" {
  for_each = var.extensions

  name                        = each.key
  virtual_machine_id          = var.virtual_machine_id
  publisher                   = each.value.publisher
  type                        = each.value.type
  type_handler_version        = each.value.type_handler_version
  auto_upgrade_minor_version  = try(each.value.auto_upgrade_minor_version, true)
  automatic_upgrade_enabled   = try(each.value.automatic_upgrade_enabled, null)
  failure_suppression_enabled = try(each.value.failure_suppression_enabled, null)
  settings                    = try(each.value.settings, null) == null ? null : jsonencode(each.value.settings)
  protected_settings          = try(each.value.protected_settings, null) == null ? null : jsonencode(each.value.protected_settings)
}
