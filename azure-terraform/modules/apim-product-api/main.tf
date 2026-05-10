resource "azurerm_api_management_product_api" "this" {
  for_each = var.links

  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  product_id          = each.value.product_id
  api_name            = each.value.api_name
}
