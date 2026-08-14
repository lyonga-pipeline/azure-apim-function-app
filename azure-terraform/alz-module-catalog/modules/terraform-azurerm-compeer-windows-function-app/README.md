# AzureRM Function App

`azurerm_windows_function_app` is a Terraform resource used to manage and deploy Windows-based Azure Functions within the Azure cloud platform. This offers the ability to provision, manage, and configure Windows-based function applications in Azure Functions. By leveraging this resource, users can easily deploy and scale their serverless solutions in Azure without concerning themselves with the underlying infrastructure.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.11, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.73.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_windows_function_app.windows_function_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_function_app) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | The Azure Region where the Windows Web App should exist. Changing this forces a new Windows Web App to be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name which should be used for this Windows Web App. Changing this forces a new Windows Web App to be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the Resource Group where the Windows Web App should exist. Changing this forces a new Windows Web App to be created. | `string` | n/a | yes |
| <a name="input_service_plan_id"></a> [service\_plan\_id](#input\_service\_plan\_id) | The ID of the Service Plan that this Windows App Service will be created in. | `string` | n/a | yes |
| <a name="input_virtual_network_subnet_id"></a> [virtual\_network\_subnet\_id](#input\_virtual\_network\_subnet\_id) | The subnet id which will be used by this Web App for regional virtual network integration. | `string` | n/a | yes |
| <a name="input_app_settings"></a> [app\_settings](#input\_app\_settings) | A map of key-value pairs of App Settings. | `map(string)` | `null` | no |
| <a name="input_auth_settings"></a> [auth\_settings](#input\_auth\_settings) | Authentication settings configuration | ```object({ enabled = bool additional_login_parameters = optional(map(string)) allowed_external_redirect_urls = optional(list(string)) runtime_version = optional(string) token_refresh_extension_hours = optional(number) token_store_enabled = optional(bool) unauthenticated_client_action = optional(string) active_directory = optional(list(object({ client_id = string allowed_audiences = optional(list(string)) client_secret = optional(string) client_secret_setting_name = optional(string) }))) microsoft = optional(list(object({ client_id = string client_secret = optional(string) client_secret_setting_name = optional(string) oauth_scopes = optional(list(string)) }))) })``` | `null` | no |
| <a name="input_backup"></a> [backup](#input\_backup) | Backup settings configuration | ```object({ name = string storage_account_url = string enabled = bool schedule = optional(list(object({ frequency_interval = string frequency_unit = string keep_at_least_one_backup = optional(bool) retention_period_days = optional(number) start_time = optional(string) }))) })``` | `null` | no |
| <a name="input_builtin_logging_enabled"></a> [builtin\_logging\_enabled](#input\_builtin\_logging\_enabled) | hould built in logging be enabled. Configures AzureWebJobsDashboard app setting based on the configured storage setting. | `bool` | `false` | no |
| <a name="input_client_certificate_enabled"></a> [client\_certificate\_enabled](#input\_client\_certificate\_enabled) | Should Client Certificates be enabled? | `bool` | `false` | no |
| <a name="input_client_certificate_exclusion_paths"></a> [client\_certificate\_exclusion\_paths](#input\_client\_certificate\_exclusion\_paths) | Paths to exclude when using client certificates, separated by ; | `string` | `null` | no |
| <a name="input_client_certificate_mode"></a> [client\_certificate\_mode](#input\_client\_certificate\_mode) | The Client Certificate mode. Possible values are Required, Optional, and OptionalInteractiveUser. This property has no effect when client\_cert\_enabled is false | `string` | `null` | no |
| <a name="input_connection_string"></a> [connection\_string](#input\_connection\_string) | One or more Connection string configuration | ```object({ name = string type = string value = string })``` | `null` | no |
| <a name="input_content_share_force_disabled"></a> [content\_share\_force\_disabled](#input\_content\_share\_force\_disabled) | Should Content Share Settings be disabled. | `bool` | `false` | no |
| <a name="input_daily_memory_time_quota"></a> [daily\_memory\_time\_quota](#input\_daily\_memory\_time\_quota) | The amount of memory in gigabyte-seconds that your application is allowed to consume per day. Setting this value only affects function apps under the consumption plan. | `number` | `0` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Should the Windows Web App be enabled? Defaults to true. | `bool` | `true` | no |
| <a name="ftp_publish_basic_authentication_enabled"></a>[ftp\_publish\_basic\_authentication\_enabled](#ftp\_publish\_basic\_authentication\_enabled) | Should the default FTP Basic Authentication publishing profile be enabled | `bool` | `true` | no |
| <a name="input_functions_extension_version"></a> [functions\_extension\_version](#input\_functions\_extension\_version) | The runtime version associated with the Function App. | `string` | `~4` | no |
| <a name="input_https_only"></a> [https\_only](#input\_https\_only) | Should the Windows Web App require HTTPS connections. | `bool` | `true` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | For setting managed identity for accessing Azure services. | ```object({ type = string identity_ids = list(string) })``` | `null` | no |
| <a name="input_key_vault_reference_identity_id"></a> [key\_vault\_reference\_identity\_id](#input\_key\_vault\_reference\_identity\_id) | The User Assigned Identity ID used for accessing KeyVault secrets. The identity must be assigned to the application in the identity block. | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Should public network access be enabled for the Web App. | `bool` | `false` | no |
| <a name="input_site_config"></a> [site\_config](#input\_site\_config) | Configuration for each site | ```object({ always_on = optional(bool) api_definition_url = optional(string) api_management_api_id = optional(string) app_command_line = optional(string) app_scale_limit = optional(number) application_insights_connection_string = optional(string) application_insights_key = optional(string) default_documents = optional(list(string)) elastic_instance_minimum = optional(number) ftps_state = optional(string) health_check_path = optional(string) health_check_eviction_time_in_min = optional(number) http2_enabled = optional(bool) load_balancing_mode = optional(string) managed_pipeline_mode = optional(string) minimum_tls_version = optional(string) pre_warmed_instance_count = optional(number) remote_debugging_enabled = optional(bool) remote_debugging_version = optional(string) runtime_scale_monitoring_enabled = optional(bool) scm_minimum_tls_version = optional(string) scm_use_main_ip_restriction = optional(bool) use_32_bit_worker = optional(bool) vnet_route_all_enabled = optional(bool) websockets_enabled = optional(bool) worker_count = optional(number) application_stack = optional(list(object({ dotnet_version = optional(string) use_dotnet_isolated_runtime = optional(bool) java_version = optional(string) node_version = optional(string) powershell_core_version = optional(string) use_custom_runtime = optional(bool) }))) app_service_logs = optional(list(object({ disk_quota_mb = optional(number) retention_period_days = optional(number) }))) cors = optional(object({ allowed_origins = list(string) support_credentials = optional(bool) })) ip_restriction = optional(list(object({ action = optional(string) headers = optional(map(string)) ip_address = optional(string) name = optional(string) priority = optional(number) service_tag = optional(string) virtual_network_subnet_id = optional(string) }))) scm_ip_restriction = optional(list(object({ action = optional(string) headers = optional(map(string)) ip_address = optional(string) name = optional(string) priority = optional(number) service_tag = optional(string) virtual_network_subnet_id = optional(string) }))) })``` | `{}` | no |
| <a name="input_sticky_settings"></a> [sticky\_settings](#input\_sticky\_settings) | Typically used for sticky session configurations. | ```object({ app_setting_names = list(string) connection_string_names = list(string) })``` | `null` | no |
| <a name="input_storage_account"></a> [storage\_account](#input\_storage\_account) | To link Azure storage accounts. | ```object({ access_key = string account_name = string name = string share_name = string type = string mount_path = optional(string) })``` | `null` | no |
| <a name="input_storage_account_access_key"></a> [storage\_account\_access\_key](#input\_storage\_account\_access\_key) | The access key which will be used to access the backend storage account for the Function App. Conflicts with storage\_uses\_managed\_identity. | `string` | `null` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | The backend storage account name which will be used by this Function App. | `string` | `null` | no |
| <a name="input_storage_key_vault_secret_id"></a> [storage\_key\_vault\_secret\_id](#input\_storage\_key\_vault\_secret\_id) | The access key which will be used to access the backend storage account for the Function App. Conflicts with storage\_uses\_managed\_identity. | `string` | `null` | no |
| <a name="input_storage_uses_managed_identity"></a> [storage\_uses\_managed\_identity](#input\_storage\_uses\_managed\_identity) | Should the Function App use Managed Identity to access the storage account. Conflicts with storage\_account\_access\_key. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags which should be assigned to the Windows Web App. | `map(string)` | `{}` | no |
[webdeploy\_publish\_basic\_authentication\_enabled](#webdeploy\_publish\_basic\_authentication\_enabled) | Should the default WebDeploy Basic Authentication publishing credentials enabled | `bool` | `true` | no |
| <a name="input_zip_deploy_file"></a> [zip\_deploy\_file](#input\_zip\_deploy\_file) | The local path and filename of the Zip packaged application to deploy to this Windows Web App. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_windows_function_id"></a> [windows\_function\_id](#output\_windows\_function\_id) | The ID of the Windows Web App. |
