resource "azurerm_windows_virtual_machine" "windows_vm" {

  name                                                   = var.virtual_machine_name
  resource_group_name                                    = var.resource_group_name
  location                                               = var.resource_group_location
  network_interface_ids                                  = [azurerm_network_interface.nic.id]
  size                                                   = var.virtual_machine_size
  admin_username                                         = var.admin_username
  admin_password                                         = local.admin_password
  license_type                                           = var.license_type
  source_image_id                                        = var.source_image_id != null ? var.source_image_id : null
  zone                                                   = var.availability_zone
  tags                                                   = merge({ "ResourceName" = var.virtual_machine_name }, var.vm_tags)
  automatic_updates_enabled                              = var.automatic_updates_enabled
  patch_mode                                             = var.patch_mode
  patch_assessment_mode                                  = var.patch_assessment_mode
  availability_set_id                                    = var.availability_set_id != null ? var.availability_set_id : try(azurerm_availability_set.availability[0].id, null)
  bypass_platform_safety_checks_on_user_schedule_enabled = var.bypass_platform_safety_checks_on_user_schedule_enabled


  dynamic "source_image_reference" {
    for_each = var.source_image_id != null ? [] : [1]
    content {
      publisher = var.source_image_reference.publisher
      offer     = var.source_image_reference.offer
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
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

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics != null ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics.storage_account_uri
    }
  }

  lifecycle {
    ignore_changes = [
      patch_mode,
      patch_assessment_mode,
      vm_agent_platform_updates_enabled,
    ]
  }
}
