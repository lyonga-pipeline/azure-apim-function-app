# Azure MSSQL Managed Instance

This module creates an Azure MSSQL Managed Instance, a fully-managed SQL Server Database Engine instance hosted in Azure cloud, providing near 100% compatibility with the latest SQL Server on-premises (Enterprise Edition) instances.

---

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.11, < 4.

---0 |

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
| [azurerm_monitor_diagnostic_setting.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_mssql_managed_instance.mssql_managed_instance](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_managed_instance) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_monitor_diagnostic_categories.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_diagnostic_categories) | data source |

### Resource Block

```hcl
resource "azurerm_mssql_managed_instance" "mssql_managed_instance" {
  ...
}
```

This declares a resource of type `azurerm_mssql_managed_instance` with a local name `mssql_managed_instance`.

#### Dynamic Identity Block

This block defines the Managed Service Identity configuration for the MSSQL Managed Instance.

```hcl
dynamic "identity" {
  ...
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_administrator_login"></a> [administrator\_login](#input\_administrator\_login) | The administrator login name for the new SQL Managed Instance. | `string` | n/a | yes |
| <a name="input_administrator_login_password"></a> [administrator\_login\_password](#input\_administrator\_login\_password) | The password associated with the administrator\_login user. Must comply with Azure's Password Policy. | `string` | n/a | yes |
| <a name="input_license_type"></a> [license\_type](#input\_license\_type) | What type of license the Managed Instance will use. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The supported Azure location where the resource exists. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the SQL Managed Instance. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the SQL Managed Instance. | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | The SKU Name for the SQL Managed Instance. | `string` | n/a | yes |
| <a name="input_storage_size_in_gb"></a> [storage\_size\_in\_gb](#input\_storage\_size\_in\_gb) | Maximum storage space for the SQL Managed instance. | `number` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The subnet resource ID that the SQL Managed Instance will be associated with. | `string` | n/a | yes |
| <a name="input_vcores"></a> [vcores](#input\_vcores) | Number of cores assigned to the SQL Managed Instance. | `number` | n/a | yes |
| <a name="input_collation"></a> [collation](#input\_collation) | Specifies how the SQL Managed Instance will be collated. | `string` | `"SQL_Latin1_General_CP1_CI_AS"` | no |
| <a name="input_dns_zone_partner_id"></a> [dns\_zone\_partner\_id](#input\_dns\_zone\_partner\_id) | The ID of the SQL Managed Instance which will share the DNS zone. | `string` | `null` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | An identity block as defined below. | ```object({ type = string identity_ids = optional(list(string)) })``` | `{}` | no |
| <a name="input_maintenance_configuration_name"></a> [maintenance\_configuration\_name](#input\_maintenance\_configuration\_name) | The name of the Public Maintenance Configuration window. | `string` | `"SQL_Default"` | no |
| <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version) | The Minimum TLS Version. | `string` | `"1.2"` | no |
| <a name="input_proxy_override"></a> [proxy\_override](#input\_proxy\_override) | Specifies how the SQL Managed Instance will be accessed. | `string` | `"Default"` | no |
| <a name="input_public_data_endpoint_enabled"></a> [public\_data\_endpoint\_enabled](#input\_public\_data\_endpoint\_enabled) | Is the public data endpoint enabled? | `bool` | `false` | no |
| <a name="input_storage_account_type"></a> [storage\_account\_type](#input\_storage\_account\_type) | The storage account type used to store backups for this database. | `string` | `"GRS"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_timezone_id"></a> [timezone\_id](#input\_timezone\_id) | The TimeZone ID that the SQL Managed Instance will operate in. | `string` | `"UTC"` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_mssql_managed_instance_fqdn"></a> [mssql\_managed\_instance\_fqdn](#output\_mssql\_managed\_instance\_fqdn) | The fully qualified domain name of the Azure Managed SQL Instance. |
| <a name="output_mssql_managed_instance_id"></a> [mssql\_managed\_instance\_id](#output\_mssql\_managed\_instance\_id) | The Microsoft SQL Managed Instance ID. |
