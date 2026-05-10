resource "azurerm_availability_set" "this" {
  name                         = var.name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  platform_fault_domain_count  = var.platform_fault_domain_count
  platform_update_domain_count = var.platform_update_domain_count
  managed                      = true
  proximity_placement_group_id = var.proximity_placement_group_id
  tags                         = var.tags
}
