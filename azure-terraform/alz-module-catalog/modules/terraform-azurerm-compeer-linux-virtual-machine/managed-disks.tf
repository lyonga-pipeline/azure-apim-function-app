resource "azurerm_managed_disk" "data" {
  for_each = local.vm_data_disks

  name                 = each.value.data_disk.name
  resource_group_name  = var.resource_group_name
  location             = var.resource_group_location
  storage_account_type = lookup(each.value.data_disk, "storage_account_type", "StandardSSD_LRS")
  create_option        = each.value.data_disk.create_option
  disk_size_gb         = each.value.data_disk.disk_size_gb
  tags                 = merge({ "ResourceName" = each.value.data_disk.name }, var.tags)

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "name" {
  for_each           = local.vm_data_disks
  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.linux_vm.id
  lun                = each.value.index
  caching            = var.os_disk_caching
}