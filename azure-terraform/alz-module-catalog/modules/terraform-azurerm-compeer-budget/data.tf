data "azurerm_resource_group" "this" {
  count = local.budget_scope_type == "resource_group" ? 1 : 0

  name = var.resource_group_name
}
