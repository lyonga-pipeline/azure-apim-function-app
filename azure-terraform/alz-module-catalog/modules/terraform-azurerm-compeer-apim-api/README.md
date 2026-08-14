# Azure API Management API

The azurerm_api_management_api resource allows you to manage APIs within an Azure API Management service.

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
| [azurerm_api_management_api.api](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_name"></a> [api\_name](#input\_api\_name) | The name of the API Management Service. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_apim_name"></a> [apim\_name](#input\_apim\_name) | The name of the API Management Service. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the Resource Group in which the API Management Service should be exist. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_revision"></a> [revision](#input\_revision) | The Revision which used for this API. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_api_type"></a> [api\_type](#input\_api\_type) | Type of API. Possible values are graphql, http, soap, and websocket. Defaults to http. | `string` | `null` | no |
| <a name="input_contact"></a> [contact](#input\_contact) | A contact block as documented below. | ```object({ email = optional(string) name = optional(string) url = optional(string) })``` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | A description of the API Management API, which may include HTML formatting tags. | `string` | `null` | no |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | The display name of the API. | `string` | `null` | no |
| <a name="input_import"></a> [import](#input\_import) | A import block as documented below. | ```object({ content_format = string content_value = string wsdl_selector = optional(object({ service_name = string endpoint_name = string })) })``` | `null` | no |
| <a name="input_license"></a> [license](#input\_license) | A license block as documented below. | ```object({ name = optional(string) url = optional(string) })``` | `null` | no |
| <a name="input_oauth2_authorization"></a> [oauth2\_authorization](#input\_oauth2\_authorization) | A oauth2\_authorization block as documented below. | ```object({ authorization_server_name = optional(string) scope = optional(string) })``` | `null` | no |
| <a name="input_openid_authentication"></a> [openid\_authentication](#input\_openid\_authentication) | A openid\_authentication block as documented below. | ```object({ openid_provider_name = optional(string) bearer_token_sending_methods = list(string) })``` | `null` | no |
| <a name="input_path"></a> [path](#input\_path) | The Path for this API Management API, which is a relative URL which uniquely identifies this API and all of its resource paths within the API Management Service. | `string` | `null` | no |
| <a name="input_protocols"></a> [protocols](#input\_protocols) | A list of protocols the operations in this API can be invoked. Possible values are http, https, ws, and wss. | `set(string)` | `null` | no |
| <a name="input_revision_description"></a> [revision\_description](#input\_revision\_description) | The description of the API Revision of the API Management API. | `string` | `null` | no |
| <a name="input_service_url"></a> [service\_url](#input\_service\_url) | Absolute URL of the backend service implementing this API. | `string` | `null` | no |
| <a name="input_source_api_id"></a> [source\_api\_id](#input\_source\_api\_id) | The API id of the source API, which could be in format azurerm\_api\_management\_api.example.id or in format azurerm\_api\_management\_api.example.id;rev=1 | `string` | `null` | no |
| <a name="input_subscription_key_parameter_names"></a> [subscription\_key\_parameter\_names](#input\_subscription\_key\_parameter\_names) | A subscription\_key\_parameter\_names block as documented below. | ```object({ header = string query = string })``` | `null` | no |
| <a name="input_subscription_required"></a> [subscription\_required](#input\_subscription\_required) | Should this API require a subscription key? Defaults to true. | `bool` | `null` | no |
| <a name="input_terms_of_service_url"></a> [terms\_of\_service\_url](#input\_terms\_of\_service\_url) | Absolute URL of the Terms of Service for the API. | `string` | `null` | no |
| <a name="input_version"></a> [version](#input\_version) | The Version number of this API, if this API is versioned. | `string` | `null` | no |
| <a name="input_version_description"></a> [version\_description](#input\_version\_description) | The description of the API Version of the API Management API. | `string` | `null` | no |
| <a name="input_version_set_id"></a> [version\_set\_id](#input\_version\_set\_id) | The ID of the Version Set which this API is associated with. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | The ID of the API Management Service API's. |
