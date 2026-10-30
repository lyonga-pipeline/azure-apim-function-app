mock_provider "azurerm" {}
variables { resource_group_name = "platform-cus-prod-services-rg" }
run "defaults_are_inert" {
  command = plan
  assert {
    condition     = length(azurerm_shared_image_gallery.platform) + length(azurerm_maintenance_configuration.patch) == 0
    error_message = "Existing callers must not receive a gallery or patching schedule."
  }
}
run "private_gallery_and_approved_patch_window" {
  command = plan
  variables {
    galleries = { platform = { name = "compeer_cus_prod_gallery", images = { windows = { name = "windows-server", os_type = "Windows", publisher = "compeer", offer = "hardened", sku = "server2022" } } } }
    patch_schedules = { pilot = {
      name                         = "monthly-pilot"
      start_date_time              = "2027-01-16 02:00"
      time_zone                    = "Central Standard Time"
      recur_every                  = "Month Third Saturday"
      approved_change_id           = "EXAMPLE-CHG-APPROVAL"
      azure_patch_mode_ready       = true
      mutually_exclusive_with_sccm = true
      virtual_machines             = { probe = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/services-rg/providers/Microsoft.Compute/virtualMachines/probe" }
    } }
  }
  assert {
    condition     = azurerm_shared_image.golden["platform/windows"].hyper_v_generation == "V2" && length(azurerm_maintenance_assignment_virtual_machine.patch) == 1
    error_message = "Use private Gen2 images and stable-key approved VM patch assignments."
  }
}
run "unapproved_patch_path_rejected" {
  command = plan
  variables {
    patch_schedules = { invalid = { name = "invalid", start_date_time = "2027-01-16 02:00", time_zone = "UTC", recur_every = "Day", approved_change_id = "", azure_patch_mode_ready = false, mutually_exclusive_with_sccm = false, virtual_machines = {} } }
  }
  expect_failures = [var.patch_schedules]
}
