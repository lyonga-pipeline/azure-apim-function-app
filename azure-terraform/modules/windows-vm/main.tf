locals {
  default_computer_name = substr(replace(replace(replace(var.name, "_", ""), ".", ""), " ", ""), 0, 15)
}

resource "azurerm_windows_virtual_machine" "this" {
  name                       = var.name
  computer_name              = coalesce(var.computer_name, local.default_computer_name)
  resource_group_name        = var.resource_group_name
  location                   = var.location
  size                       = var.vm_size
  admin_username             = var.admin_username
  admin_password             = var.admin_password
  network_interface_ids      = var.network_interface_ids
  zone                       = var.zone
  availability_set_id        = var.availability_set_id
  provision_vm_agent         = var.provision_vm_agent
  allow_extension_operations = var.allow_extension_operations
  enable_automatic_updates   = var.enable_automatic_updates
  patch_mode                 = var.patch_mode
  patch_assessment_mode      = var.patch_assessment_mode
  hotpatching_enabled        = var.hotpatching_enabled
  secure_boot_enabled        = var.secure_boot_enabled
  vtpm_enabled               = var.vtpm_enabled
  encryption_at_host_enabled = var.encryption_at_host_enabled
  timezone                   = var.timezone
  license_type               = var.license_type
  tags                       = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics == null ? [] : [var.boot_diagnostics]
    content {
      storage_account_uri = try(boot_diagnostics.value.storage_account_uri, null)
    }
  }

  dynamic "additional_capabilities" {
    for_each = var.additional_capabilities == null ? [] : [var.additional_capabilities]
    content {
      ultra_ssd_enabled = try(additional_capabilities.value.ultra_ssd_enabled, false)
    }
  }

  os_disk {
    caching                   = var.os_disk.caching
    storage_account_type      = var.os_disk.storage_account_type
    disk_size_gb              = try(var.os_disk.disk_size_gb, null)
    name                      = try(var.os_disk.name, null)
    write_accelerator_enabled = try(var.os_disk.write_accelerator_enabled, null)
    disk_encryption_set_id    = try(var.os_disk.disk_encryption_set_id, null)
  }

  dynamic "plan" {
    for_each = var.plan == null ? [] : [var.plan]
    content {
      name      = plan.value.name
      publisher = plan.value.publisher
      product   = plan.value.product
    }
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_id == null ? [var.source_image_reference] : []
    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  source_image_id = var.source_image_id

  lifecycle {
    precondition {
      condition     = (var.zone == null || var.availability_set_id == null)
      error_message = "zone and availability_set_id cannot both be set."
    }
    precondition {
      condition     = var.source_image_id == null || var.source_image_reference == null
      error_message = "Set either source_image_id or source_image_reference, not both."
    }
    precondition {
      condition     = var.source_image_id != null || var.source_image_reference != null
      error_message = "One of source_image_id or source_image_reference must be set."
    }
    precondition {
      condition     = !var.hotpatching_enabled || (var.patch_mode == "AutomaticByPlatform" && var.provision_vm_agent)
      error_message = "hotpatching_enabled requires patch_mode AutomaticByPlatform and provision_vm_agent true."
    }
    precondition {
      condition     = try(length(var.network_interface_ids) > 0, false)
      error_message = "At least one network_interface_id is required."
    }
  }
}
