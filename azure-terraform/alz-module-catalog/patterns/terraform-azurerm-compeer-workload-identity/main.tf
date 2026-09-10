locals {
  federated_credentials = merge([
    for identity_key, identity in var.workload_identities : {
      for credential_key, credential in identity.federated_credentials :
      "${identity_key}::${credential_key}" => merge(credential, { identity_key = identity_key })
    }
  ]...)

  azure_role_assignments = merge([
    for identity_key, identity in var.workload_identities : {
      for assignment_key, assignment in identity.azure_role_assignments :
      "${identity_key}::${assignment_key}" => merge(assignment, { identity_key = identity_key })
    }
  ]...)
}

module "application" {
  source   = "../../modules/terraform-azuread-compeer-ad-application"
  for_each = var.workload_identities

  display_name            = each.value.display_name
  description             = try(each.value.description, null)
  owners                  = try(each.value.owners, [])
  notes                   = try(each.value.notes, null)
  sign_in_audience        = try(each.value.sign_in_audience, "AzureADMyOrg")
  prevent_duplicate_names = try(each.value.prevent_duplicate_names, true)
  tags                    = try(each.value.tags, ["terraform", "landing-zone"])
}

module "service_principal" {
  source   = "../../modules/terraform-azuread-compeer-service-principal"
  for_each = var.workload_identities

  client_id   = module.application[each.key].client_id
  owners      = try(each.value.owners, [])
  tags        = try(each.value.tags, ["terraform", "landing-zone"])
  description = "Service principal for ${each.value.display_name}"
  notes       = try(each.value.notes, null)
}

resource "azuread_application_federated_identity_credential" "this" {
  for_each = local.federated_credentials

  application_id = module.application[each.value.identity_key].id
  display_name   = each.value.display_name
  description    = try(each.value.description, null)
  audiences      = try(each.value.audiences, ["api://AzureADTokenExchange"])
  issuer         = each.value.issuer
  subject        = each.value.subject
}

resource "azurerm_role_assignment" "this" {
  for_each = local.azure_role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = module.service_principal[each.value.identity_key].object_id
  principal_type       = "ServicePrincipal"
  description          = try(each.value.description, null)
  condition            = try(each.value.condition, null)
  condition_version    = try(each.value.condition_version, null)
}

module "operational_contracts" {
  source = "../../modules/terraform-azurerm-compeer-operational-contracts"

  contracts = var.operational_contracts
}
