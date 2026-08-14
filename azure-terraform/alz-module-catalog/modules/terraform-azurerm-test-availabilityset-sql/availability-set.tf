resource "azurerm_availability_set" "availability" {
  count                        = var.enable_availability_set ? 1 : 0
  name                         = local.availability_set_name
  resource_group_name          = var.resource_group_name
  location                     = var.resource_group_location
  platform_fault_domain_count  = var.platform_fault_domain_count
  platform_update_domain_count = var.platform_update_domain_count
  managed                      = var.managed_availability_set
  tags                         = merge({ "ResourceName" = local.availability_set_name }, var.avs_tags)

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
