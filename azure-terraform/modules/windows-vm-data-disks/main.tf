resource "azurerm_managed_disk" "this" {
  for_each = var.disks

  name                          = coalesce(try(each.value.name, null), "${var.name_prefix}-${each.key}")
  location                      = var.location
  resource_group_name           = var.resource_group_name
  storage_account_type          = each.value.storage_account_type
  create_option                 = try(each.value.create_option, "Empty")
  disk_size_gb                  = each.value.disk_size_gb
  zone                          = try(each.value.zone, var.zone)
  disk_encryption_set_id        = try(each.value.disk_encryption_set_id, null)
  public_network_access_enabled = false
  tags                          = merge(var.tags, try(each.value.tags, {}))
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each = var.disks

  managed_disk_id           = azurerm_managed_disk.this[each.key].id
  virtual_machine_id        = var.virtual_machine_id
  lun                       = each.value.lun
  caching                   = each.value.caching
  write_accelerator_enabled = try(each.value.write_accelerator_enabled, null)
}
