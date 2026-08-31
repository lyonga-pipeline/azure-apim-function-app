resource "azurerm_api_management_identity_provider_aad" "apim_identity_provider_aad" {
  for_each = var.aad == null ? {} : { aad = var.aad }

  api_management_name = var.apim_name
  resource_group_name = var.resource_group_name
  client_id           = each.value.client_id
  client_secret       = each.value.client_secret
  allowed_tenants     = each.value.allowed_tenants
  client_library      = try(each.value.client_library, "MSAL-2")
  signin_tenant       = try(each.value.signin_tenant, null)
}

resource "azurerm_api_management_identity_provider_aadb2c" "apim_identity_provider_aadb2c" {
  for_each = var.aadb2c == null ? {} : { aadb2c = var.aadb2c }

  api_management_name    = var.apim_name
  resource_group_name    = var.resource_group_name
  client_id              = each.value.client_id
  client_secret          = each.value.client_secret
  allowed_tenant         = each.value.allowed_tenant
  signin_tenant          = each.value.signin_tenant
  authority              = each.value.authority
  signin_policy          = each.value.signin_policy
  signup_policy          = try(each.value.signup_policy, null)
  password_reset_policy  = try(each.value.password_reset_policy, null)
  profile_editing_policy = try(each.value.profile_editing_policy, null)
}
