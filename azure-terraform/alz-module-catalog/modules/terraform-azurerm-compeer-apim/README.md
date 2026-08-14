# Azure API Management

The azurerm_api_management resource is used to manage an API Management Service in Azure. API Management is a fully managed service that enables customers to publish, secure, transform, maintain, and monitor APIs.

---

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.11, < 4.0 |

---

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.75.0 |

---

## Modules

No modules.

---

## Resources

| Name | Type |
|------|------|
| [azurerm_api_management.apim](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management) | resource |
| [azurerm_monitor_diagnostic_setting.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_monitor_diagnostic_categories.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_diagnostic_categories) | data source |

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apim_name"></a> [apim\_name](#input\_apim\_name) | The name of the API Management Service. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_diagnostic_setting_name"></a> [diagnostic\_setting\_name](#input\_diagnostic\_setting\_name) | Name for the diagnostic settings | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The Azure location where the API Management Service exists. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Specifices the ID of the Log Analytics Workspace where Diagnostic Data should be sent | `string` | n/a | yes |
| <a name="input_publisher_email"></a> [publisher\_email](#input\_publisher\_email) | The email of publisher/company. | `string` | n/a | yes |
| <a name="input_publisher_name"></a> [publisher\_name](#input\_publisher\_name) | The name of publisher/company. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the Resource Group in which the API Management Service should be exist. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | sku\_name is a string consisting of two parts separated by an underscore(\_). The first part is the name, valid values include: Consumption, Developer, Basic, Standard and Premium. The second part is the capacity (e.g. the number of deployed units of the sku), which must be a positive integer (e.g. Developer\_1). | `string` | n/a | yes |
| <a name="input_additional_location"></a> [additional\_location](#input\_additional\_location) | One or more additional\_location blocks as defined below. | ```list(object({ location = string capacity = optional(number) zones = optional(set(string)) public_ip_address_id = optional(string) gateway_disabled = optional(bool) virtual_network_configuration = optional(object({ subnet_id = string })) }))``` | `[]` | no |
| <a name="input_certificate"></a> [certificate](#input\_certificate) | One or more (up to 10) certificate blocks as defined below. | ```list(object({ encoded_certificate = string store_name = string certificate_password = optional(string) }))``` | `[]` | no |
| <a name="input_client_certificate_enabled"></a> [client\_certificate\_enabled](#input\_client\_certificate\_enabled) | Enforce a client certificate to be presented on each request to the gateway? This is only supported when SKU type is Consumption. | `bool` | `false` | no |
| <a name="input_delegation"></a> [delegation](#input\_delegation) | A delegation block as defined below. | ```object({ subscriptions_enabled = optional(bool) user_registration_enabled = optional(bool) url = optional(string) validation_key = optional(string) })``` | `null` | no |
| <a name="input_gateway_disabled"></a> [gateway\_disabled](#input\_gateway\_disabled) | Disable the gateway in main region? This is only supported when additional\_location is set. | `bool` | `null` | no |
| <a name="input_hostname_configuration"></a> [hostname\_configuration](#input\_hostname\_configuration) | An hostname\_configuration block as defined below. | ```object({ management = optional(object({ host_name = string key_vault_id = optional(string) certificate = optional(string) certificate_password = optional(string) negotiate_client_certificate = optional(bool) ssl_keyvault_identity_client_id = optional(string) })) portal = optional(object({ host_name = string key_vault_id = optional(string) certificate = optional(string) certificate_password = optional(string) negotiate_client_certificate = optional(bool) ssl_keyvault_identity_client_id = optional(string) })) developer_portal = optional(object({ host_name = string key_vault_id = optional(string) certificate = optional(string) certificate_password = optional(string) negotiate_client_certificate = optional(bool) ssl_keyvault_identity_client_id = optional(string) })) proxy = optional(object({ host_name = string key_vault_id = optional(string) certificate = optional(string) certificate_password = optional(string) negotiate_client_certificate = optional(bool) ssl_keyvault_identity_client_id = optional(string) })) scm = optional(object({ host_name = string key_vault_id = optional(string) certificate = optional(string) certificate_password = optional(string) negotiate_client_certificate = optional(bool) ssl_keyvault_identity_client_id = optional(string) })) })``` | `null` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | An identity block as defined below. | ```object({ type = string identity_ids = set(string) })``` | `null` | no |
| <a name="input_log_analytics_destination_type"></a> [log\_analytics\_destination\_type](#input\_log\_analytics\_destination\_type) | When set to 'Dedicated' logs sent to Log Analytics workspace will go into resource specific tables, instead of the legacy AzureDiagnostics table | `string` | `"AzureDiagnostics"` | no |
| <a name="input_min_api_version"></a> [min\_api\_version](#input\_min\_api\_version) | The version which the control plane API calls to API Management service are limited with version equal to or newer than. | `number` | `null` | no |
| <a name="input_notification_sender_email"></a> [notification\_sender\_email](#input\_notification\_sender\_email) | Email address from which the notification will be sent. | `string` | `null` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | An policy block as defined below. | ```object({ xml_content = optional(string) xml_link = optional(string) })``` | `null` | no |
| <a name="input_protocols"></a> [protocols](#input\_protocols) | An protocols block as defined below. | ```object({ enable_http2 = bool })``` | `null` | no |
| <a name="input_public_ip_address_id"></a> [public\_ip\_address\_id](#input\_public\_ip\_address\_id) | ID of a standard SKU IPv4 Public IP. | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Is public access to the service allowed? | `bool` | `false` | no |
| <a name="input_security"></a> [security](#input\_security) | An security block as defined below. | ```object({ enable_backend_ssl30 = optional(bool) enable_backend_tls10 = optional(bool) enable_backend_tls11 = optional(bool) enable_frontend_ssl30 = optional(bool) enable_frontend_tls10 = optional(bool) enable_frontend_tls11 = optional(bool) tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled = optional(bool) tls_ecdhe_ecdsa_with_aes256_cbc_sha_ciphers_enabled = optional(bool) tls_ecdhe_rsa_with_aes128_cbc_sha_ciphers_enabled = optional(bool) tls_ecdhe_rsa_with_aes256_cbc_sha_ciphers_enabled = optional(bool) tls_rsa_with_aes128_cbc_sha256_ciphers_enabled = optional(bool) tls_rsa_with_aes128_cbc_sha_ciphers_enabled = optional(bool) tls_rsa_with_aes128_gcm_sha256_ciphers_enabled = optional(bool) tls_rsa_with_aes256_gcm_sha384_ciphers_enabled = optional(bool) tls_rsa_with_aes256_cbc_sha256_ciphers_enabled = optional(bool) tls_rsa_with_aes256_cbc_sha_ciphers_enabled = optional(bool) triple_des_ciphers_enabled = optional(bool) })``` | `null` | no |
| <a name="input_sign_in"></a> [sign\_in](#input\_sign\_in) | An sign\_in block as defined below. | ```object({ enabled = bool })``` | `null` | no |
| <a name="input_sign_up"></a> [sign\_up](#input\_sign\_up) | An sign\_up block as defined below. | ```object({ enabled = bool terms_of_service = object({ consent_required = bool enabled = bool text = string }) })``` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags assigned to the resource. | `map(string)` | `{}` | no |
| <a name="input_tenant_access"></a> [tenant\_access](#input\_tenant\_access) | An tenant\_access block as defined below. | ```object({ enabled = bool })``` | `null` | no |
| <a name="input_virtual_network_configuration"></a> [virtual\_network\_configuration](#input\_virtual\_network\_configuration) | A virtual\_network\_configuration block as defined below. Required when virtual\_network\_type is External or Internal. | ```object({ subnet_id = string })``` | `null` | no |
| <a name="input_virtual_network_type"></a> [virtual\_network\_type](#input\_virtual\_network\_type) | The type of virtual network you want to use, valid values include: None, External, Internal. | `string` | `null` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | Specifies a list of Availability Zones in which this API Management service should be located. Changing this forces a new API Management service to be created. | `set(string)` | `null` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apim_id"></a> [apim\_id](#output\_apim\_id) | The ID of the API Management Service. |
