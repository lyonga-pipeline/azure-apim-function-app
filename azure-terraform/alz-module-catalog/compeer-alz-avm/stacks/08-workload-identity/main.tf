locals {
  federated_credentials = merge({}, [
    for identity_key, identity in var.workload_identities : {
      for credential_key, credential in try(identity.federated_credentials, {}) :
      "${identity_key}-${credential_key}" => merge(credential, {
        identity_key = identity_key
      })
    }
  ]...)
}

module "ad_application" {
  for_each = var.workload_identities
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-ad-application/azuread"
  version  = "1.0.7"

  display_name            = each.value.display_name
  description             = try(each.value.description, null)
  owners                  = try(each.value.owners, [])
  prevent_duplicate_names = try(each.value.prevent_duplicate_names, true)
  sign_in_audience        = try(each.value.sign_in_audience, "AzureADMyOrg")
  tags                    = try(each.value.tags, ["terraform", "landing-zone"])
}

module "service_principal" {
  for_each = var.workload_identities
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-service-principal/azuread"
  version  = "1.0.1"

  client_id    = module.ad_application[each.key].client_id
  owners       = try(each.value.owners, [])
  tags         = try(each.value.tags, ["terraform", "landing-zone"])
  use_existing = false
  description  = "Service principal for ${each.value.display_name}"
}

resource "azuread_application_federated_identity_credential" "this" {
  for_each = local.federated_credentials

  application_id = module.ad_application[each.value.identity_key].id
  display_name   = each.value.display_name
  description    = try(each.value.description, null)
  audiences      = try(each.value.audiences, ["api://AzureADTokenExchange"])
  issuer         = each.value.issuer
  subject        = each.value.subject
}
