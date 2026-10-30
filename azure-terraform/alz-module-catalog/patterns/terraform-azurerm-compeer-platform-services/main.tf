# PHASE2 NEW: v5 8.1. Private/RBAC gallery; no community/public image sharing.
resource "azurerm_shared_image_gallery" "platform" {
  for_each            = var.galleries
  name                = each.value.name
  description         = each.value.description
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
resource "azurerm_shared_image" "golden" {
  for_each                 = local.images
  name                     = each.value.name
  gallery_name             = azurerm_shared_image_gallery.platform[each.value.gallery_key].name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  os_type                  = each.value.os_type
  hyper_v_generation       = "V2"
  trusted_launch_supported = true
  identifier {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
  }
  tags = var.tags
}
# PHASE2 NEW: v5 8.2. VM owners set AutomaticByPlatform/customer-managed schedules beforehand.
resource "azurerm_maintenance_configuration" "patch" {
  for_each                 = var.patch_schedules
  name                     = each.value.name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  scope                    = "InGuestPatch"
  in_guest_user_patch_mode = "User"
  window {
    start_date_time = each.value.start_date_time
    time_zone       = each.value.time_zone
    recur_every     = each.value.recur_every
    duration        = each.value.duration
  }
  install_patches {
    reboot = each.value.reboot
    windows { classifications_to_include = each.value.windows_classifications }
    linux { classifications_to_include = each.value.linux_classifications }
  }
  tags = var.tags
}
resource "azurerm_maintenance_assignment_virtual_machine" "patch" {
  for_each                     = local.assignments
  location                     = var.location
  virtual_machine_id           = each.value.vm_id
  maintenance_configuration_id = azurerm_maintenance_configuration.patch[each.value.schedule_key].id
}
