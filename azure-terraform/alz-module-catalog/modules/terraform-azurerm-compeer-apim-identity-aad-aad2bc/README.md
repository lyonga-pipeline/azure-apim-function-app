# Azure API Management AAD and AADB2C

The azurerm_api_management_identity_provider_aad and azurerm_api_management_identity_provider_aadb2c resource allows you to manage AAD and AADB2C config within an Azure API Management service.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.11, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.11, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_api_management_identity_provider_aad.apim_identity_provider_aad](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_identity_provider_aad) | resource |
| [azurerm_api_management_identity_provider_aadb2c.apim_identity_provider_aadb2c](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_identity_provider_aadb2c) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aad_allowed_tenants"></a> [aad\_allowed\_tenants](#input\_aad\_allowed\_tenants) | List of allowed AAD Tenants. | `list(string)` | `null` | no |
| <a name="input_aad_client_id"></a> [aad\_client\_id](#input\_aad\_client\_id) | Client Id of the Application in the AAD Identity Provider. | `string` | `null` | no |
| <a name="input_aad_client_library"></a> [aad\_client\_library](#input\_aad\_client\_library) | The client library to use for the AAD Identity Provider. Possible values are 'MSAL-2' and 'ADAL'. | `string` | `"MSAL-2"` | no |
| <a name="input_aad_client_secret"></a> [aad\_client\_secret](#input\_aad\_client\_secret) | Client secret of the Application in the AAD Identity Provider. | `string` | `null` | no |
| <a name="input_aad_signin_tenant"></a> [aad\_signin\_tenant](#input\_aad\_signin\_tenant) | The AAD Tenant to use instead of Common when logging into Active Directory | `string` | `null` | no |
| <a name="input_aadb2c_allowed_tenant"></a> [aadb2c\_allowed\_tenant](#input\_aadb2c\_allowed\_tenant) | The allowed AAD tenant, usually your B2C tenant domain. | `string` | `null` | no |
| <a name="input_aadb2c_authority"></a> [aadb2c\_authority](#input\_aadb2c\_authority) | OpenID Connect discovery endpoint hostname, usually your b2clogin.com domain. | `string` | `null` | no |
| <a name="input_aadb2c_client_id"></a> [aadb2c\_client\_id](#input\_aadb2c\_client\_id) | Client ID of the Application in your B2C tenant. | `string` | `null` | no |
| <a name="input_aadb2c_client_secret"></a> [aadb2c\_client\_secret](#input\_aadb2c\_client\_secret) | Client secret of the Application in your B2C tenant. | `string` | `null` | no |
| <a name="input_aadb2c_password_reset_policy"></a> [aadb2c\_password\_reset\_policy](#input\_aadb2c\_password\_reset\_policy) | Password reset Policy Name. | `string` | `null` | no |
| <a name="input_aadb2c_profile_editing_policy"></a> [aadb2c\_profile\_editing\_policy](#input\_aadb2c\_profile\_editing\_policy) | Profile editing Policy Name. | `string` | `null` | no |
| <a name="input_aadb2c_signin_policy"></a> [aadb2c\_signin\_policy](#input\_aadb2c\_signin\_policy) | Signin Policy Name. | `string` | `null` | no |
| <a name="input_aadb2c_signin_tenant"></a> [aadb2c\_signin\_tenant](#input\_aadb2c\_signin\_tenant) | The tenant to use instead of Common when logging into Active Directory, usually your B2C tenant domain. | `string` | `null` | no |
| <a name="input_aadb2c_signup_policy"></a> [aadb2c\_signup\_policy](#input\_aadb2c\_signup\_policy) | Signup Policy Name | `string` | `null` | no |
| <a name="input_apim_name"></a> [apim\_name](#input\_apim\_name) | The Name of the API Management Service where this AAD Identity Provider should be created. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_create_apim_aad_idp"></a> [create\_apim\_aad\_idp](#input\_create\_apim\_aad\_idp) | Whether to create Azure APIM Identity provider AAD | `bool` | `false` | no |
| <a name="input_create_apim_aadb2c_idp"></a> [create\_apim\_aadb2c\_idp](#input\_create\_apim\_aadb2c\_idp) | Whether to create Azure APIM Identity provider AADB2C | `bool` | `false` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The Name of the Resource Group where the API Management Service exists. Changing this forces a new resource to be created. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_identity_aad_id"></a> [identity\_aad\_id](#output\_identity\_aad\_id) | The ID of the API Management AAD Identity Provider. |
| <a name="output_identity_aadb2c_id"></a> [identity\_aadb2c\_id](#output\_identity\_aadb2c\_id) | The ID of the API Management Azure AD B2C Identity Provider Resource. |
