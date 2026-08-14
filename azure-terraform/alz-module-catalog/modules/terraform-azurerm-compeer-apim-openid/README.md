# Azure API Management OpenID Connect Provider

The azurerm_api_management_openid_connect_provider resource allows you to manage OpenID config within an Azure API Management service.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.11, < 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.11, < 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_api_management_openid_connect_provider.apim_openid_connect_provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_openid_connect_provider) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apim_name"></a> [apim\_name](#input\_apim\_name) | The name of the API Management Service in which this OpenID Connect Provider should be created. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_client_id"></a> [client\_id](#input\_client\_id) | The Client ID used for the Client Application. | `string` | n/a | yes |
| <a name="input_client_secret"></a> [client\_secret](#input\_client\_secret) | The Client Secret used for the Client Application. | `string` | n/a | yes |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | A user-friendly name for this OpenID Connect Provider. | `string` | n/a | yes |
| <a name="input_metadata_endpoint"></a> [metadata\_endpoint](#input\_metadata\_endpoint) | The URI of the Metadata endpoint. | `string` | n/a | yes |
| <a name="input_openid_provider_name"></a> [openid\_provider\_name](#input\_openid\_provider\_name) | The Name of the OpenID Connect Provider which should be created within the API Management Service. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the Resource Group where the API Management Service exists. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | A description of this OpenID Connect Provider. | `string` | `null` | no |

## Outputs

No outputs.
