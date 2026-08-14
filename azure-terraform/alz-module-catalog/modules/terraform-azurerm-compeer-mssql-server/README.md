# Azure MSSQL Server

This module creates an Azure MSSQL Server, a managed service provided by Microsoft Azure that delivers predictable performance, scalability with business continuity and data protection.

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
| [azurerm_monitor_diagnostic_setting.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_mssql_server.mssql_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_monitor_diagnostic_categories.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_diagnostic_categories) | data source |

### Resource Block

```hcl
resource "azurerm_mssql_server" "mssql_server" {
  ...
}
```

This declares a resource of type `azurerm_mssql_server` with a local name `mssql_server`.

#### Dynamic Blocks

##### Dynamic Identity Block

This block is used to configure Managed Service Identity on the SQL Server.

```hcl
dynamic "identity" {
  ...
}
```

##### Dynamic Azure AD Administrator Block

This block configures the Azure AD Administrator for the SQL Server.

```hcl
dynamic "azuread_administrator" {
  ...
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the resource exists. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the Microsoft SQL Server. This needs to be globally unique within Azure. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the Microsoft SQL Server. | `string` | n/a | yes |
| <a name="input_version"></a> [version](#input\_version) | The version for the new server. Valid values are: 2.0 (for v11 server) and 12.0 (for v12 server). | `string` | n/a | yes |
| <a name="input_administrator_login"></a> [administrator\_login](#input\_administrator\_login) | The administrator login name for the new server. | `string` | `null` | no |
| <a name="input_administrator_login_password"></a> [administrator\_login\_password](#input\_administrator\_login\_password) | The password associated with the administrator\_login user. Needs to comply with Azure's Password Policy. | `string` | `null` | no |
| <a name="input_azuread_administrator"></a> [azuread\_administrator](#input\_azuread\_administrator) | Azure AD Administrator configuration for SQL Server | ```object({ login_username = string object_id = string tenant_id = optional(string) azuread_authentication_only = optional(bool) })``` | `null` | no |
| <a name="input_connection_policy"></a> [connection\_policy](#input\_connection\_policy) | The connection policy the server will use. Possible values are Default, Proxy, and Redirect. | `string` | `"Default"` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | Identity configuration for SQL Server | ```object({ type = string identity_ids = optional(list(string)) })``` | `null` | no |
| <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version) | The Minimum TLS Version for all SQL Database and SQL Data Warehouse databases associated with the server. | `string` | `"1.2"` | no |
| <a name="input_outbound_network_restriction_enabled"></a> [outbound\_network\_restriction\_enabled](#input\_outbound\_network\_restriction\_enabled) | Whether outbound network traffic is restricted for this server. | `bool` | `false` | no |
| <a name="input_primary_user_assigned_identity_id"></a> [primary\_user\_assigned\_identity\_id](#input\_primary\_user\_assigned\_identity\_id) | Specifies the primary user managed identity id. Required if type is UserAssigned and should be combined with identity\_ids. | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether public network access is allowed for this server. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_transparent_data_encryption_key_vault_key_id"></a> [transparent\_data\_encryption\_key\_vault\_key\_id](#input\_transparent\_data\_encryption\_key\_vault\_key\_id) | The fully versioned Key Vault Key URL to be used as the Customer Managed Key for the Transparent Data Encryption layer. | `string` | `null` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_mssql_server_fully_qualified_domain_name"></a> [mssql\_server\_fully\_qualified\_domain\_name](#output\_mssql\_server\_fully\_qualified\_domain\_name) | The fully qualified domain name of the Azure SQL Server (e.g. myServerName.database.windows.net). |
| <a name="output_mssql_server_id"></a> [mssql\_server\_id](#output\_mssql\_server\_id) | The Microsoft SQL Server ID. |
