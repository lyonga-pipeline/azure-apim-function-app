output "gallery_ids" { value = { for key, value in azurerm_shared_image_gallery.platform : key => value.id } }
output "image_definition_ids" { value = { for key, value in azurerm_shared_image.golden : key => value.id } }
output "maintenance_configuration_ids" { value = { for key, value in azurerm_maintenance_configuration.patch : key => value.id } }
output "maintenance_assignment_ids" { value = { for key, value in azurerm_maintenance_assignment_virtual_machine.patch : key => value.id } }
