resource "azurerm_eventgrid_topic" "main" {
  name                          = var.eventgrid_topic_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  input_schema                  = var.eventgrid_input_schema
  public_network_access_enabled = var.public_network_access_enabled
  local_auth_enabled            = var.local_auth_enabled

  identity {
    type         = var.eventgrid_identity_type
    identity_ids = var.eventgrid_identity_ids
  }
}