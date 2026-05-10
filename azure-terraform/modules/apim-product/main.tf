resource "azurerm_api_management_product" "this" {
  product_id            = var.product_id
  api_management_name   = var.api_management_name
  resource_group_name   = var.resource_group_name
  display_name          = var.display_name
  approval_required     = var.approval_required
  published             = var.published
  subscription_required = var.subscription_required
  subscriptions_limit   = var.subscriptions_limit
  terms                 = var.terms
  description           = var.description
}
