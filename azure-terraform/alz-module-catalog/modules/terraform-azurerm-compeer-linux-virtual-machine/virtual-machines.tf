resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                            = var.name
  computer_name                   = var.computer_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  network_interface_ids           = var.network_interface_ids
  admin_username                  = var.admin_username
  admin_password                  = var.disable_password_authentication ? null : var.admin_password
  disable_password_authentication = var.disable_password_authentication
  zone                            = var.zone
  availability_set_id             = var.availability_set_id
  provision_vm_agent              = var.provision_vm_agent
  allow_extension_operations      = var.allow_extension_operations
  patch_mode                      = var.patch_mode
  patch_assessment_mode           = var.patch_assessment_mode
  encryption_at_host_enabled      = var.encryption_at_host_enabled
  secure_boot_enabled             = var.secure_boot_enabled
  vtpm_enabled                    = var.vtpm_enabled
  license_type                    = var.license_type
  user_data                       = var.user_data
  custom_data                     = var.custom_data
  source_image_id                 = var.source_image_id
  tags                            = var.tags

  dynamic "admin_ssh_key" {
    for_each = var.admin_ssh_keys
    content {
      username   = coalesce(try(admin_ssh_key.value.username, null), var.admin_username)
      public_key = admin_ssh_key.value.public_key
    }
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_id == null && var.source_image_reference != null ? [var.source_image_reference] : []
    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  dynamic "plan" {
    for_each = var.plan == null ? [] : [var.plan]
    content {
      name      = plan.value.name
      publisher = plan.value.publisher
      product   = plan.value.product
    }
  }

  os_disk {
    name                      = try(var.os_disk.name, null)
    caching                   = var.os_disk.caching
    storage_account_type      = var.os_disk.storage_account_type
    disk_encryption_set_id    = try(var.os_disk.disk_encryption_set_id, null)
    disk_size_gb              = try(var.os_disk.disk_size_gb, null)
    write_accelerator_enabled = try(var.os_disk.write_accelerator_enabled, null)
  }

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(length(identity.value.identity_ids), 0) == 0 ? null : identity.value.identity_ids
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics == null ? [] : [var.boot_diagnostics]
    content { storage_account_uri = try(boot_diagnostics.value.storage_account_uri, null) }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    read   = try(var.timeouts.read, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }

  lifecycle {
    precondition {
      condition     = var.zone == null || var.availability_set_id == null
      error_message = "availability_zone and availability_set_id cannot both be set."
    }
    precondition {
      condition     = (var.source_image_id == null) != (var.source_image_reference == null)
      error_message = "Configure exactly one of source_image_id or source_image_reference."
    }
    precondition {
      condition     = !var.disable_password_authentication || length(var.admin_ssh_keys) > 0
      error_message = "At least one admin_ssh_keys entry is required when password authentication is disabled."
    }
    precondition {
      condition     = var.disable_password_authentication || var.admin_password != null
      error_message = "admin_password is required when password authentication is enabled."
    }
    precondition {
      condition     = var.identity == null ? true : (!strcontains(var.identity.type, "UserAssigned") || length(try(var.identity.identity_ids, [])) > 0)
      error_message = "identity.identity_ids must be provided when identity.type includes UserAssigned."
    }
    precondition {
      condition     = length(var.network_interface_ids) > 0
      error_message = "At least one externally managed network interface ID is required."
    }
  }
}
