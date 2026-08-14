resource "azurerm_api_management_openid_connect_provider" "apim_openid_connect_provider" {
  api_management_name = var.apim_name
  resource_group_name = var.resource_group_name
  name                = var.openid_provider_name
  client_id           = var.client_id
  client_secret       = var.client_secret
  display_name        = var.display_name
  metadata_endpoint   = var.metadata_endpoint
  description         = var.description
}