# Azure API Management Backend

The azurerm_api_management_backend resource allows you to manage backend config within an Azure API Management service.

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
| [azurerm_api_management_backend.apim_backend](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_backend) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apim_backend_name"></a> [apim\_backend\_name](#input\_apim\_backend\_name) | The name of the API Management backend. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_apim_backend_protocol"></a> [apim\_backend\_protocol](#input\_apim\_backend\_protocol) | The protocol used by the backend host. Possible values are http or soap. | `string` | n/a | yes |
| <a name="input_apim_backend_url"></a> [apim\_backend\_url](#input\_apim\_backend\_url) | The URL of the backend host. | `string` | n/a | yes |
| <a name="input_apim_name"></a> [apim\_name](#input\_apim\_name) | The Name of the API Management Service where this backend should be created. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The Name of the Resource Group where the API Management Service exists. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_apim_backend_description"></a> [apim\_backend\_description](#input\_apim\_backend\_description) | The description of the backend. | `string` | `null` | no |
| <a name="input_apim_backend_resource_id"></a> [apim\_backend\_resource\_id](#input\_apim\_backend\_resource\_id) | The management URI of the backend host in an external system. This URI can be the ARM Resource ID of Logic Apps, Function Apps or API Apps, or the management endpoint of a Service Fabric cluster. | `string` | `null` | no |
| <a name="input_apim_backend_title"></a> [apim\_backend\_title](#input\_apim\_backend\_title) | The title of the backend. | `string` | `null` | no |
| <a name="input_credentials"></a> [credentials](#input\_credentials) | A credentials block as documented below. | ```object({ authorization = optional(object({ parameter = optional(string) scheme = optional(string) })) certificate = optional(list(string)) header = optional(map(string)) query = optional(map(string)) })``` | `null` | no |
| <a name="input_proxy"></a> [proxy](#input\_proxy) | A proxy block as documented below. | ```object({ password = optional(string) url = string username = string })``` | `null` | no |
| <a name="input_service_fabric_cluster"></a> [service\_fabric\_cluster](#input\_service\_fabric\_cluster) | A service\_fabric\_cluster block as documented below. | ```object({ management_endpoints = list(string) max_partition_resolution_retries = number client_certificate_thumbprint = optional(string) client_certificate_id = optional(string) server_certificate_thumbprints = optional(list(string)) server_x509_name = optional(object({ issuer_certificate_thumbprint = string name = string })) })``` | `null` | no |
| <a name="input_tls"></a> [tls](#input\_tls) | A tls block as documented below. | ```object({ validate_certificate_chain = optional(bool) validate_certificate_name = optional(bool) })``` | `null` | no |

## Outputs

No outputs.
