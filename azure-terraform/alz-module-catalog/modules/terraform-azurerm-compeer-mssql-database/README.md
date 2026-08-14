## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.11, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.11, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_mssql_database.mssql_database](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_pause_delay_in_minutes"></a> [auto\_pause\_delay\_in\_minutes](#input\_auto\_pause\_delay\_in\_minutes) | Time in minutes after which database is automatically paused. A value of -1 means that automatic pause is disabled. This property is only settable for General Purpose Serverless databases. | `number` | `-1` | no |
| <a name="input_collation"></a> [collation](#input\_collation) | Specifies the collation of the database. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_create_mode"></a> [create\_mode](#input\_create\_mode) | The create mode of the database. | `string` | `null` | no |
| <a name="input_creation_source_database_id"></a> [creation\_source\_database\_id](#input\_creation\_source\_database\_id) | The ID of the source database from which to create the new database. This should only be used for databases with create\_mode values that use another database as reference. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_elastic_pool_id"></a> [elastic\_pool\_id](#input\_elastic\_pool\_id) | Specifies the ID of the elastic pool containing this database. | `string` | `null` | no |
| <a name="input_geo_backup_enabled"></a> [geo\_backup\_enabled](#input\_geo\_backup\_enabled) | A boolean that specifies if the Geo Backup Policy is enabled. Defaults to true. | `bool` | `null` | no |
| <a name="input_import"></a> [import](#input\_import) | A Database Import block as documented below. Mutually exclusive with create\_mode. | <pre>object({<br>    storage_uri                  = string<br>    storage_key                  = string<br>    storage_key_type             = string<br>    administrator_login          = string<br>    administrator_login_password = string<br>    authentication_type          = string<br>    storage_account_id           = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_ledger_enabled"></a> [ledger\_enabled](#input\_ledger\_enabled) | A boolean that specifies if this is a ledger database. Defaults to false. Changing this forces a new resource to be created. | `bool` | `null` | no |
| <a name="input_license_type"></a> [license\_type](#input\_license\_type) | Specifies the license type applied to this database. | `string` | `null` | no |
| <a name="input_long_term_retention_policy"></a> [long\_term\_retention\_policy](#input\_long\_term\_retention\_policy) | A long\_term\_retention\_policy block as defined below. | <pre>object({<br>    weekly_retention  = optional(string)<br>    monthly_retention = optional(string)<br>    yearly_retention  = optional(string)<br>    week_of_year      = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_maintenance_configuration_name"></a> [maintenance\_configuration\_name](#input\_maintenance\_configuration\_name) | The name of the Public Maintenance Configuration window to apply to the database. | `string` | `null` | no |
| <a name="input_max_size_gb"></a> [max\_size\_gb](#input\_max\_size\_gb) | The max size of the database in gigabytes. | `number` | `null` | no |
| <a name="input_min_capacity"></a> [min\_capacity](#input\_min\_capacity) | Minimal capacity that database will always have allocated, if not paused. This property is only settable for General Purpose Serverless databases. | `number` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Microsoft SQL Server. This needs to be globally unique within Azure. | `string` | n/a | yes |
| <a name="input_read_replica_count"></a> [read\_replica\_count](#input\_read\_replica\_count) | The number of readonly secondary replicas associated with the database to which readonly application intent connections may be routed. This property is only settable for Hyperscale edition databases. | `number` | `null` | no |
| <a name="input_read_scale"></a> [read\_scale](#input\_read\_scale) | If enabled, connections that have application intent set to readonly in their connection string may be routed to a readonly secondary replica. This property is only settable for Premium and Business Critical databases. | `bool` | `null` | no |
| <a name="input_recover_database_id"></a> [recover\_database\_id](#input\_recover\_database\_id) | The ID of the database to be recovered. This property is only applicable when the create\_mode is Recovery. | `string` | `null` | no |
| <a name="input_restore_dropped_database_id"></a> [restore\_dropped\_database\_id](#input\_restore\_dropped\_database\_id) | The ID of the database to be restored. This property is only applicable when the create\_mode is Restore. | `string` | `null` | no |
| <a name="input_restore_point_in_time"></a> [restore\_point\_in\_time](#input\_restore\_point\_in\_time) | Specifies the point in time (ISO8601 format) of the source database that will be restored to create the new database. This property is only settable for create\_mode= PointInTimeRestore databases. | `string` | `null` | no |
| <a name="input_sample_name"></a> [sample\_name](#input\_sample\_name) | Specifies the name of the sample schema to apply when creating this database. | `string` | `null` | no |
| <a name="input_server_id"></a> [server\_id](#input\_server\_id) | The id of the MS SQL Server on which to create the database. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_short_term_retention_policy"></a> [short\_term\_retention\_policy](#input\_short\_term\_retention\_policy) | A short\_term\_retention\_policy block as defined below. | <pre>object({<br>    retention_days           = number<br>    backup_interval_in_hours = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | Specifies the name of the SKU used by the database. For example, GP\_S\_Gen5\_2,HS\_Gen4\_1,BC\_Gen5\_2, ElasticPool, Basic,S0, P2 ,DW100c, DS100. Changing this from the HyperScale service tier to another service tier will create a new resource. | `string` | `null` | no |
| <a name="input_storage_account_type"></a> [storage\_account\_type](#input\_storage\_account\_type) | Specifies the storage account type used to store backups for this database. Possible values are Geo, Local and Zone. | `string` | `"Geo"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_threat_detection_policy"></a> [threat\_detection\_policy](#input\_threat\_detection\_policy) | Threat detection policy configuration. The threat\_detection\_policy block supports fields documented below. | <pre>object({<br>    state                      = optional(string)<br>    disabled_alerts            = optional(list(string))<br>    email_account_admins       = optional(string)<br>    email_addresses            = optional(list(string))<br>    retention_days             = optional(number)<br>    storage_account_access_key = optional(string)<br>    storage_endpoint           = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_transparent_data_encryption_enabled"></a> [transparent\_data\_encryption\_enabled](#input\_transparent\_data\_encryption\_enabled) | If set to true, Transparent Data Encryption will be enabled on the database. | `bool` | `null` | no |
| <a name="input_zone_redundant"></a> [zone\_redundant](#input\_zone\_redundant) | Whether or not this database is zone redundant, which means the replicas of this database will be spread across multiple availability zones. This property is only settable for Premium and Business Critical databases. | `bool` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_mssql_database_id"></a> [mssql\_database\_id](#output\_mssql\_database\_id) | The Microsoft SQL Database ID. |
