# AzureRM Linux Web App

`azurerm_linux_web_app` is a Terraform resource tailored for managing and deploying Linux-based web apps within the Azure cloud platform. This resource empowers users to provision, configure, and manage Linux-centric web applications hosted in Azure App Service.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.11, < 5.0 |

---

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.72.0 |

---

## Modules

No modules.

---

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_web_app.linux_web_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | The Azure Region where the Linux Web App should exist. Changing this forces a new Linux Web App to be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name which should be used for this Linux Web App. Changing this forces a new Linux Web App to be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the Resource Group where the Linux Web App should exist. Changing this forces a new Linux Web App to be created. | `string` | n/a | yes |
| <a name="input_service_plan_id"></a> [service\_plan\_id](#input\_service\_plan\_id) | The ID of the Service Plan that this Linux App Service will be created in. | `string` | n/a | yes |
| <a name="input_app_settings"></a> [app\_settings](#input\_app\_settings) | A map of key-value pairs of App Settings. | `map(string)` | `null` | no |
| <a name="input_auth_settings"></a> [auth\_settings](#input\_auth\_settings) | Authentication settings configuration | ```object({ enabled = bool additional_login_parameters = optional(map(string)) allowed_external_redirect_urls = optional(list(string)) active_directory = optional(list(object({ client_id = string allowed_audiences = optional(list(string)) client_secret = optional(string) client_secret_setting_name = optional(string) }))) microsoft = optional(list(object({ client_id = string client_secret = optional(string) client_secret_setting_name = optional(string) oauth_scopes = optional(list(string)) }))) runtime_version = optional(string) token_refresh_extension_hours = optional(number) token_store_enabled = optional(bool) unauthenticated_client_action = optional(string) })``` | `null` | no |
| <a name="input_backup"></a> [backup](#input\_backup) | Backup settings configuration | ```object({ name = string storage_account_url = string enabled = bool schedule = optional(list(object({ frequency_interval = string frequency_unit = string keep_at_least_one_backup = optional(bool) retention_period_days = optional(number) start_time = optional(string) }))) })``` | `null` | no |
| <a name="input_client_affinity_enabled"></a> [client\_affinity\_enabled](#input\_client\_affinity\_enabled) | Should Client Affinity be enabled? | `bool` | `false` | no |
| <a name="input_client_certificate_enabled"></a> [client\_certificate\_enabled](#input\_client\_certificate\_enabled) | Should Client Certificates be enabled? | `bool` | `false` | no |
| <a name="input_client_certificate_exclusion_paths"></a> [client\_certificate\_exclusion\_paths](#input\_client\_certificate\_exclusion\_paths) | Paths to exclude when using client certificates, separated by ; | `string` | `null` | no |
| <a name="input_client_certificate_mode"></a> [client\_certificate\_mode](#input\_client\_certificate\_mode) | The Client Certificate mode. Possible values are Required, Optional, and OptionalInteractiveUser. This property has no effect when client\_cert\_enabled is false | `string` | `null` | no |
| <a name="input_connection_string"></a> [connection\_string](#input\_connection\_string) | One or more Connection string configuration | ```object({ name = string type = string value = string })``` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Should the Linux Web App be enabled? Defaults to true. | `bool` | `true` | no |
| <a name="input_https_only"></a> [https\_only](#input\_https\_only) | Should the Linux Web App require HTTPS connections. | `bool` | `false` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | For setting managed identity for accessing Azure services. | ```object({ type = string identity_ids = list(string) })``` | `null` | no |
| <a name="input_key_vault_reference_identity_id"></a> [key\_vault\_reference\_identity\_id](#input\_key\_vault\_reference\_identity\_id) | The User Assigned Identity ID used for accessing KeyVault secrets. The identity must be assigned to the application in the identity block. | `string` | `null` | no |
| <a name="input_logs"></a> [logs](#input\_logs) | Logging settings configuration | ```object({ application_logs = optional(object({ azure_blob_storage = optional(list(object({ level = string retention_in_days = optional(number) sas_url = optional(string) }))) file_system_level = optional(string) })) detailed_error_messages = optional(bool) failed_request_tracing = optional(bool) http_logs = optional(object({ azure_blob_storage = optional(list(object({ retention_in_days = optional(number) sas_url = optional(string) }))) file_system = optional(list(object({ retention_in_days = optional(number) retention_in_mb = optional(number) }))) })) })``` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Should public network access be enabled for the Web App. | `bool` | `true` | no |
| <a name="input_site_config"></a> [site\_config](#input\_site\_config) | Configuration for each site | ```list(object({ always_on = optional(bool) api_definition_url = optional(string) api_management_api_id = optional(string) app_command_line = optional(string) application_stack = optional(list(object({ docker_image_name = optional(string) docker_registry_url = optional(string) docker_registry_username = optional(string) docker_registry_password = optional(string) dotnet_version = optional(string) go_version = optional(string) java_server = optional(string) java_server_version = optional(bool) java_version = optional(string) node_version = optional(string) php_version = optional(string) python_version = optional(string) ruby_versions = optional(string) }))) auto_heal_setting = optional(list(object({ action = optional(list(object({ action_type = optional(string) custom_action = optional(list(object({ executable = optional(string) parameters = optional(string) }))) minimum_process_execution_time = optional(string) }))) trigger = optional(list(object({ private_memory_kb = optional(string) requests = optional(list(object({ count = optional(string) interval = optional(string) }))) slow_request = optional(list(object({ count = optional(string) interval = optional(string) time_taken = optional(string) }))) status_code = optional(list(object({ count = optional(string) interval = optional(string) status_code_range = optional(string) path = optional(string) sub_status = optional(string) win32_status = optional(string) }))) }))) }))) container_registry_managed_identity_client_id = optional(string) container_registry_use_managed_identity = optional(bool) cors = optional(object({ allowed_origins = list(string) support_credentials = optional(bool) })) default_documents = optional(list(string)) ftps_state = optional(string) health_check_path = optional(string) health_check_eviction_time_in_min = optional(number) http2_enabled = optional(bool) ip_restriction = optional(list(object({ action = optional(string) headers = optional(map(string)) ip_address = optional(string) name = optional(string) priority = optional(number) service_tag = optional(string) virtual_network_subnet_id = optional(string) }))) load_balancing_mode = optional(string) local_mysql_enabled = optional(bool) managed_pipeline_mode = optional(string) minimum_tls_version = optional(string) remote_debugging_enabled = optional(bool) remote_debugging_version = optional(string) scm_ip_restriction = optional(list(object({ action = optional(string) headers = optional(map(string)) ip_address = optional(string) name = optional(string) priority = optional(number) service_tag = optional(string) virtual_network_subnet_id = optional(string) }))) scm_minimum_tls_version = optional(string) scm_use_main_ip_restriction = optional(bool) use_32_bit_worker = optional(bool) virtual_application = optional(list(object({ physical_path = string preload = bool virtual_directory = optional(list(object({ physical_path = optional(string) virtual_path = optional(string) }))) virtual_path = string }))) vnet_route_all_enabled = optional(bool) websockets_enabled = optional(bool) worker_count = optional(number) }))``` | `[]` | no |
| <a name="input_sticky_settings"></a> [sticky\_settings](#input\_sticky\_settings) | Typically used for sticky session configurations. | ```object({ app_setting_names = list(string) connection_string_names = list(string) })``` | `null` | no |
| <a name="input_storage_account"></a> [storage\_account](#input\_storage\_account) | To link Azure storage accounts. | ```object({ access_key = string account_name = string name = string share_name = string type = string mount_path = optional(string) })``` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags which should be assigned to the Linux Web App. | `map(string)` | `{}` | no |
| <a name="input_virtual_network_subnet_id"></a> [virtual\_network\_subnet\_id](#input\_virtual\_network\_subnet\_id) | The subnet id which will be used by this Web App for regional virtual network integration. | `string` | `null` | no |
| <a name="input_zip_deploy_file"></a> [zip\_deploy\_file](#input\_zip\_deploy\_file) | The local path and filename of the Zip packaged application to deploy to this Linux Web App. | `string` | `null` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_linux_webapp_id"></a> [linux\_webapp\_id](#output\_linux\_webapp\_id) | The ID of the Linux Web App. |

---

### Note

For more details and advanced configurations, please refer to the official documentation on Terraform's website: [Terraform Azurerm Provider - Linux Web App Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app).
