resource "azurerm_api_management_identity_provider_aad" "apim_identity_provider_aad" {
  count               = var.create_apim_aad_idp ? 1 : 0
  api_management_name = var.apim_name
  resource_group_name = var.resource_group_name
  client_id           = var.aad_client_id
  client_secret       = var.aad_client_secret
  allowed_tenants     = var.aad_allowed_tenants
  client_library      = var.aad_client_library
  signin_tenant       = var.aad_signin_tenant
}

resource "azurerm_api_management_identity_provider_aadb2c" "apim_identity_provider_aadb2c" {
  count                  = var.create_apim_aadb2c_idp ? 1 : 0
  api_management_name    = var.apim_name
  resource_group_name    = var.resource_group_name
  client_id              = var.aadb2c_client_id
  client_secret          = var.aadb2c_client_secret
  allowed_tenant         = var.aadb2c_allowed_tenant
  signin_tenant          = var.aadb2c_signin_tenant
  authority              = var.aadb2c_authority
  signin_policy          = var.aadb2c_signin_policy
  signup_policy          = var.aadb2c_signup_policy
  password_reset_policy  = var.aadb2c_password_reset_policy
  profile_editing_policy = var.aadb2c_profile_editing_policy
}
