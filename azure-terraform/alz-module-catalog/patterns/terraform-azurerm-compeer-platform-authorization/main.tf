module "rbac_groups" {
  source   = "../../modules/terraform-azuread-compeer-ad-group"
  for_each = var.rbac_groups

  display_name            = each.value.display_name
  description             = try(each.value.description, null)
  security_enabled        = true
  mail_enabled            = false
  mail_nickname           = try(each.value.mail_nickname, null)
  members                 = try(each.value.members, null)
  owners                  = try(each.value.owners, null)
  assignable_to_role      = try(each.value.assignable_to_role, false)
  prevent_duplicate_names = try(each.value.prevent_duplicate_names, true)
}

module "custom_role_definitions" {
  source   = "../../modules/terraform-azurerm-compeer-role-definition"
  for_each = var.custom_role_definitions

  name               = each.value.name
  scope              = each.value.scope
  description        = try(each.value.description, null)
  role_definition_id = try(each.value.role_definition_id, null)
  assignable_scopes  = try(each.value.assignable_scopes, null)
  permissions        = each.value.permissions
}

locals {
  custom_role_definition_ids = {
    for key, role in module.custom_role_definitions : key => role.role_definition_resource_id
  }

  unresolved_group_keys = sort(tolist(setsubtract(
    toset([for ra in values(var.role_assignments) : ra.group_key if try(ra.group_key, null) != null]),
    toset(keys(var.rbac_groups)),
  )))

  unresolved_role_keys = sort(tolist(setsubtract(
    toset([for ra in values(var.role_assignments) : ra.role_definition_key if try(ra.role_definition_key, null) != null]),
    toset(keys(var.custom_role_definitions)),
  )))

  # Unresolvable references fall back to a placeholder GUID so plan does not hard-
  # error inside coalesce(); terraform_data.role_assignment_contract then fails
  # the run with a precise message.
  unresolved_principal_placeholder = "00000000-0000-0000-0000-000000000000"

  role_assignment_inputs = {
    for key, ra in var.role_assignments : key => {
      name  = try(ra.name, null)
      scope = ra.scope
      principal_id = try(ra.principal_id, null) != null ? ra.principal_id : try(
        module.rbac_groups[ra.group_key].object_id,
        local.unresolved_principal_placeholder,
      )
      principal_type       = try(ra.principal_type, "Group")
      role_definition_name = try(ra.role_definition_name, null)
      role_definition_id = try(ra.role_definition_name, null) != null ? null : (
        try(local.custom_role_definition_ids[ra.role_definition_key], null)
      )
      description                      = try(ra.description, null)
      condition                        = try(ra.condition, null)
      condition_version                = try(ra.condition_version, null)
      skip_service_principal_aad_check = try(ra.skip_service_principal_aad_check, null)
    }
  }
}

resource "terraform_data" "role_assignment_contract" {
  input = { keys = sort(keys(var.role_assignments)) }

  lifecycle {
    precondition {
      condition     = length(local.unresolved_group_keys) == 0
      error_message = "role_assignments reference group_key values not in rbac_groups: ${join(", ", local.unresolved_group_keys)}."
    }
    precondition {
      condition     = length(local.unresolved_role_keys) == 0
      error_message = "role_assignments reference role_definition_key values not in custom_role_definitions: ${join(", ", local.unresolved_role_keys)}."
    }
  }
}

module "role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.role_assignment_inputs

  depends_on = [terraform_data.role_assignment_contract]
}

module "operational_contracts" {
  source = "../../modules/terraform-azurerm-compeer-operational-contracts"

  contracts = var.operational_contracts
}
