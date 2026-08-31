resource "azurerm_managed_disk" "data_disk" {
  for_each = { for disk in var.data_disks : disk.name => disk }

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_type = each.value.storage_account_type
  create_option        = each.value.create_option
  disk_size_gb         = each.value.disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  for_each = { for disk in var.data_disks : disk.name => disk }

  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.windows_vm.id
  lun                = each.value.lun
  caching            = each.value.caching
}
