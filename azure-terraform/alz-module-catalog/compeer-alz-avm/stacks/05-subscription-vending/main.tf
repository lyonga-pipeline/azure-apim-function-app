# GOV-03/GOV-04. Current published landing-zone vending module.
module "subscription" {
  for_each = var.subscriptions
  source   = "Azure/lz-vending/azurerm"
  version  = "7.0.3"

  location                                          = var.location
  subscription_alias_enabled                        = true
  subscription_alias_name                           = each.value.alias_name
  subscription_display_name                         = each.value.display_name
  subscription_billing_scope                        = each.value.billing_scope
  subscription_workload                             = each.value.workload
  subscription_management_group_association_enabled = true
  subscription_management_group_id                  = each.value.management_group_id
  subscription_tags                                 = each.value.tags
  subscription_register_resource_providers_enabled  = true
}
