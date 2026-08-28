resource "azurerm_monitor_data_collection_endpoint" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  kind                          = var.kind
  description                   = var.description
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}
