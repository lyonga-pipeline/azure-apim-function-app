output "managed_disk_ids" {
  value = { for key, value in azurerm_managed_disk.this : key => value.id }
}
