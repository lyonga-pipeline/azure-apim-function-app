locals {
  resource_group_name = var.create_resource_group ? try(azurerm_resource_group.rg[0].name, var.resource_group_name) : var.resource_group_name
  location            = var.create_resource_group ? try(azurerm_resource_group.rg[0].location, var.location) : var.location
  resource_group_id   = var.create_resource_group ? try(azurerm_resource_group.rg[0].id, var.resource_group_id) : var.resource_group_id
}