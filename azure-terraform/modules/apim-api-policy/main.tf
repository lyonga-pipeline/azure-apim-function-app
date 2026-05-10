resource "azurerm_api_management_api_policy" "this" {
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  api_name            = var.api_name
  xml_content         = var.xml_content
  xml_link            = var.xml_link
}
