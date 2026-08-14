resource "azurerm_linux_virtual_machine" "linux_vm" {

  name                       = var.virtual_machine_name
  resource_group_name        = var.resource_group_name
  location                   = var.resource_group_location
  network_interface_ids      = [azurerm_network_interface.nic.id]
  size                       = var.virtual_machine_size
  admin_username             = var.admin_username
  admin_password             = var.admin_password
  provision_vm_agent         = true
  allow_extension_operations = true
  source_image_id            = var.source_image_id != null ? var.source_image_id : null
  zone                       = var.availability_zone
  tags                       = merge({ "ResourceName" = var.virtual_machine_name }, var.tags)
  patch_mode                 = var.patch_mode
  patch_assessment_mode      = var.patch_assessment_mode
  availability_set_id        = var.enable_availability_set ? element(concat(azurerm_availability_set.availability.*.id, [""]), 0) : null
  user_data                  = var.user_data
  custom_data                = var.custom_data

  dynamic "admin_ssh_key" {
    for_each = var.disable_password_authentication ? [1] : []
    content {
      username   = var.admin_username
      public_key = try(file(var.admin_ssh_key_data), var.admin_ssh_key_data)
    }
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_id != null ? [] : [1]
    content {
      publisher = var.source_image_reference.publisher
      offer     = var.source_image_reference.offer
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }

  dynamic "plan" {
    for_each = var.plan != null ? [1] : []
    content {
      name      = var.plan.name
      publisher = var.plan.publisher
      product   = var.plan.product
    }
  }

  os_disk {
    name                      = var.os_disk_name
    caching                   = var.os_disk_caching
    storage_account_type      = var.os_disk_storage_account_type
    disk_encryption_set_id    = var.disk_encryption_set_id
    disk_size_gb              = var.disk_size_gb
    write_accelerator_enabled = var.enable_os_disk_write_accelerator
  }

  dynamic "identity" {
    for_each = var.managed_identity_type != null ? [1] : []
    content {
      type         = var.managed_identity_type
      identity_ids = var.managed_identity_type == "UserAssigned" || var.managed_identity_type == "SystemAssigned, UserAssigned" ? var.managed_identity_ids : null
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
      admin_password,
      admin_ssh_key,
      patch_mode,
      custom_data,
      patch_assessment_mode,
      vm_agent_platform_updates_enabled,
    ]
  }
}
