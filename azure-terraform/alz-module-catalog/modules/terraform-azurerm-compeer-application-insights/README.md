# AzureRM Application Insights

`azurerm_application_insights` is a Terraform resource used to manage and configure Application Insights resources within the Azure cloud platform. This provides the capability to monitor the availability, performance, and usage of your web applications.

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
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.11, < 4.0 |

---

## Modules

No modules.

---

## Resources

| Name | Type |
|------|------|
| [azurerm_application_insights.application_insights](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_type"></a> [application\_type](#input\_application\_type) | Specifies the type of Application Insights to create. Valid values are ios for iOS, java for Java web, MobileCenter for App Center, Node.JS for Node.js, other for General, phone for Windows Phone, store for Windows Store and web for ASP.NET. Please note these values are case sensitive; unmatched values are treated as ASP.NET by Azure. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Specifies the name of the Application Insights component. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the Application Insights component. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_daily_data_cap_in_gb"></a> [daily\_data\_cap\_in\_gb](#input\_daily\_data\_cap\_in\_gb) | Specifies the Application Insights component daily data volume cap in GB. | `number` | `null` | no |
| <a name="input_daily_data_cap_notifications_disabled"></a> [daily\_data\_cap\_notifications\_disabled](#input\_daily\_data\_cap\_notifications\_disabled) | Specifies if a notification email will be send when the daily data volume cap is met. | `bool` | `null` | no |
| <a name="input_disable_ip_masking"></a> [disable\_ip\_masking](#input\_disable\_ip\_masking) | By default the real client IP is masked as 0.0.0.0 in the logs. Use this argument to disable masking and log the real client IP. | `bool` | `null` | no |
| <a name="input_force_customer_storage_for_profiler"></a> [force\_customer\_storage\_for\_profiler](#input\_force\_customer\_storage\_for\_profiler) | Should the Application Insights component force users to create their own storage account for profiling? | `bool` | `false` | no |
| <a name="input_internet_ingestion_enabled"></a> [internet\_ingestion\_enabled](#input\_internet\_ingestion\_enabled) | Should the Application Insights component support ingestion over the Public Internet? | `bool` | `false` | no |
| <a name="input_internet_query_enabled"></a> [internet\_query\_enabled](#input\_internet\_query\_enabled) | Should the Application Insights component support querying over the Public Internet? | `bool` | `false` | no |
| <a name="input_local_authentication_disabled"></a> [local\_authentication\_disabled](#input\_local\_authentication\_disabled) | Disable Non-Azure AD based Auth. | `bool` | `null` | no |
| <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days) | Specifies the retention period in days. Possible values are 30, 60, 90, 120, 180, 270, 365, 550 or 730. Defaults to 90. | `number` | `30` | no |
| <a name="input_sampling_percentage"></a> [sampling\_percentage](#input\_sampling\_percentage) | Specifies the percentage of the data produced by the monitored application that is sampled for Application Insights telemetry. | `number` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_workspace_id"></a> [workspace\_id](#input\_workspace\_id) | Specifies the id of a log analytics workspace resource. | `string` | `null` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_insights_id"></a> [application\_insights\_id](#output\_application\_insights\_id) | The ID of the Application Insights component. |

---

### Note

For more details and advanced configurations, please refer to the official documentation on Terraform's website: [Terraform Azurerm Provider - Application Insights Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights).
