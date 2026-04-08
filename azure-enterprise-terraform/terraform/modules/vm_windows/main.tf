locals {
  default_computer_name = substr(replace(replace(replace(var.name, "_", ""), ".", ""), " ", ""), 0, 15)
}

resource "azurerm_network_interface" "this" {
  name                          = "${var.name}-nic"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = var.enable_accelerated_networking
  enable_ip_forwarding          = var.enable_ip_forwarding
  dns_servers                   = var.dns_servers
  tags                          = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip_address_allocation == "Static" ? var.private_ip_address : null
    public_ip_address_id          = var.public_ip_address_id
  }

  lifecycle {
    precondition {
      condition     = var.private_ip_address_allocation == "Dynamic" || var.private_ip_address != null
      error_message = "private_ip_address must be set when private_ip_address_allocation is Static."
    }
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  count                     = var.network_security_group_id == null ? 0 : 1
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.network_security_group_id
}

resource "azurerm_network_interface_application_security_group_association" "this" {
  for_each                      = toset(var.application_security_group_ids)
  network_interface_id          = azurerm_network_interface.this.id
  application_security_group_id = each.value
}

resource "azurerm_windows_virtual_machine" "this" {
  name                       = var.name
  computer_name              = var.computer_name != null ? var.computer_name : local.default_computer_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  size                       = var.vm_size
  admin_username             = var.admin_username
  admin_password             = var.admin_password
  network_interface_ids      = [azurerm_network_interface.this.id]
  provision_vm_agent         = var.provision_vm_agent
  allow_extension_operations = var.allow_extension_operations
  enable_automatic_updates   = var.enable_automatic_updates
  patch_mode                 = var.patch_mode
  patch_assessment_mode      = var.patch_assessment_mode
  hotpatching_enabled        = var.hotpatching_enabled
  timezone                   = var.timezone
  secure_boot_enabled        = var.secure_boot_enabled
  vtpm_enabled               = var.vtpm_enabled
  encryption_at_host_enabled = var.encryption_at_host_enabled
  license_type               = var.license_type
  zone                       = var.zone
  tags                       = var.tags

  dynamic "identity" {
    for_each = var.identity_type == "None" ? [] : [1]

    content {
      type         = var.identity_type
      identity_ids = contains(["UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type) ? var.identity_ids : null
    }
  }

  dynamic "additional_capabilities" {
    for_each = var.ultra_ssd_enabled ? [1] : []

    content {
      ultra_ssd_enabled = true
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_storage_account_uri == null ? [] : [1]

    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
    name                 = var.os_disk_name
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  lifecycle {
    precondition {
      condition     = !var.hotpatching_enabled || (var.patch_mode == "AutomaticByPlatform" && var.provision_vm_agent)
      error_message = "hotpatching_enabled requires patch_mode to be AutomaticByPlatform and provision_vm_agent to be true."
    }

    precondition {
      condition     = !contains(["UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type) || length(var.identity_ids) > 0
      error_message = "identity_ids must contain at least one user-assigned identity when identity_type includes UserAssigned."
    }
  }
}

resource "azurerm_managed_disk" "data" {
  for_each = var.data_disks

  name                          = "${var.name}-${each.key}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  storage_account_type          = each.value.storage_account_type
  create_option                 = each.value.create_option
  disk_size_gb                  = each.value.size_gb
  disk_encryption_set_id        = coalesce(try(each.value.disk_encryption_set_id, null), var.disk_encryption_set_id)
  public_network_access_enabled = false
  zone                          = var.zone
  tags                          = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each = var.data_disks

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.this.id
  lun                = each.value.lun
  caching            = each.value.caching
}
