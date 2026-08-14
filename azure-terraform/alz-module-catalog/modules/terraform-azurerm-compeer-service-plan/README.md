# Azure App Service Plan

This Terraform module creates an Azure App Service Plan which provides the hosting environment for Azure App Services.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.11, < 4.0 |

---

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.67.0 |

---

## Resources

| Name | Type |
|------|------|
| [azurerm_service_plan.service_plan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_plan) | resource |

### Resource Block

```hcl
resource "azurerm_service_plan" "service_plan" {
  ...
}
```

This declares a resource of type `azurerm_service_plan` with a local name `service_plan`.

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the App Service Plan. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The Azure Region in which to create the App Service Plan. | `string` | n/a | yes |
| <a name="input_os_type"></a> [os_type](#input\_os\_type) | The operating system type. Can be either "Linux" or "Windows". | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource_group_name](#input\_resource\_group\_name) | The name of the resource group in which to create the App Service Plan. | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku_name](#input\_sku\_name) | The SKU name for the App Service Plan. | `string` | n/a | yes |
| <a name="input_app_service_environment_id"></a> [app_service_environment_id](#input\_app\_service\_environment\_id) | The ID of the App Service Environment. | `string` | `null` | no |
| <a name="input_maximum_elastic_worker_count"></a> [maximum_elastic_worker_count](#input\_maximum\_elastic\_worker\_count) | The maximum number of total workers allowed for this App Service Plan. | `number` | `null` | no |
| <a name="input_worker_count"></a> [worker_count](#input\_worker\_count) | Number of workers to be allocated. | `number` | `null` | no |
| <a name="input_per_site_scaling_enabled"></a> [per_site_scaling_enabled](#input\_per\_site\_scaling\_enabled) | Whether per-site scaling is enabled for this App Service Plan. | `bool` | `false` | no |
| <a name="input_zone_balancing_enabled"></a> [zone_balancing_enabled](#input\_zone\_balancing\_enabled) | Whether zone balancing is enabled for this App Service Plan. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags which should be assigned to the AppService. | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="service_plan_id"></a> [service_plan_id](#output\_service\_plan\_id) | The ID of the App Service Plan. |
| <a name="service_plan_kind"></a> [service_plan_kind](#output\_service\_plan\_kind) | A string representing the Kind of Service Plan. |
