resource "azurerm_api_management_policy" "this" {
  api_management_id = var.api_management_id
  xml_content       = var.xml_content
  xml_link          = var.xml_link
}
