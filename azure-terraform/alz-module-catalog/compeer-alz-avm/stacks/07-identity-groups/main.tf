module "rbac_groups" {
  for_each = var.rbac_groups
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-ad-group/azuread"
  version  = "1.0.0"

  display_name            = each.value.display_name
  description             = try(each.value.description, null)
  security_enabled        = true
  mail_enabled            = false
  mail_nickname           = try(each.value.mail_nickname, null)
  members                 = try(each.value.members, null)
  owners                  = try(each.value.owners, null)
  prevent_duplicate_names = try(each.value.prevent_duplicate_names, true)
  assignable_to_role      = try(each.value.assignable_to_role, false)
}

module "operational_contracts" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-operational-contracts/azurerm"
  version = "1.0.0"

  contracts = var.operational_contracts
}
