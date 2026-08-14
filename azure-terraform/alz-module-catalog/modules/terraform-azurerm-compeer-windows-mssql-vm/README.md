## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.2.0, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.2.0, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_managed_disk.data_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_mssql_virtual_machine.mssql_virtual_machine](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_virtual_machine) | resource |
| [azurerm_network_interface.nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_virtual_machine_data_disk_attachment.data_disk_attachment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_extension.join-domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_windows_virtual_machine.windows_vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accelerated_networking_enabled"></a> [accelerated\_networking\_enabled](#input\_accelerated\_networking\_enabled) | Should Accelerated Networking be enabled? Defaults to false. | `bool` | `true` | no |
| <a name="input_active_directory_domain"></a> [active\_directory\_domain](#input\_active\_directory\_domain) | Name of the Active Directory domain to join. | `string` | `"agstar.local"` | no |
| <a name="input_active_directory_password"></a> [active\_directory\_password](#input\_active\_directory\_password) | Password of the account with permissions to bind machines to the Active Directory Domain. | `string` | `null` | no |
| <a name="input_active_directory_username"></a> [active\_directory\_username](#input\_active\_directory\_username) | Username of an account with permissions to bind machines to the Active Directory Domain. | `string` | `"agstar\\svc_terraform"` | no |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | The Password which should be used for the local-administrator on this Virtual Machine | `string` | `null` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | The username of the local administrator used for the Virtual Machine. | `string` | n/a | yes |
| <a name="input_assessment"></a> [assessment](#input\_assessment) | An assessment block as defined below. | <pre>object({<br>    enabled         = optional(bool)<br>    run_immediately = optional(bool)<br>    schedule = object({<br>      weekly_interval    = optional(number)<br>      monthly_occurrence = optional(number)<br>      day_of_week        = optional(string)<br>      start_time         = string<br>    })<br>  })</pre> | `null` | no |
| <a name="input_auto_backup"></a> [auto\_backup](#input\_auto\_backup) | An auto\_backup block as defined below. This block can be added to an existing resource, but removing this block forces a new resource to be created. | <pre>object({<br>    encryption_password = optional(string, null)<br>    manual_schedule = object({<br>      full_backup_frequency           = string<br>      full_backup_start_hour          = number<br>      full_backup_window_in_hours     = number<br>      log_backup_frequency_in_minutes = number<br>      days_of_week                    = optional(set(string))<br>    })<br>    retention_period_in_days        = number<br>    storage_blob_endpoint           = string<br>    storage_account_access_key      = string<br>    system_databases_backup_enabled = optional(bool)<br>  })</pre> | `null` | no |
| <a name="input_auto_patching"></a> [auto\_patching](#input\_auto\_patching) | An auto\_patching block as defined below. | <pre>object({<br>    day_of_week                            = string<br>    maintenance_window_starting_hour       = number<br>    maintenance_window_duration_in_minutes = number<br>  })</pre> | `null` | no |
| <a name="input_bypass_platform_safety_checks_on_user_schedule_enabled"></a> [bypass\_platform\_safety\_checks\_on\_user\_schedule\_enabled](#input\_bypass\_platform\_safety\_checks\_on\_user\_schedule\_enabled) | Indicates whether to bypass platform safety checks when user schedule is enabled. This is required when the VMSS has more than 100 instances. Changing this forces a new resource to be created. | `bool` | `false` | no |
| <a name="input_data_disks"></a> [data\_disks](#input\_data\_disks) | List of data disks and their properties | <pre>list(object({<br>    name                 = string<br>    storage_account_type = string<br>    create_option        = string<br>    disk_size_gb         = number<br>    lun                  = number<br>    caching              = string<br>  }))</pre> | `[]` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | List of dns servers to use for network interface | `list(string)` | `[]` | no |
| <a name="input_enable_ad_join"></a> [enable\_ad\_join](#input\_enable\_ad\_join) | Whether to enable AD join. | `bool` | `false` | no |
| <a name="input_internal_dns_name_label"></a> [internal\_dns\_name\_label](#input\_internal\_dns\_name\_label) | The (relative) DNS Name used for internal communications between Virtual Machines in the same Virtual Network. | `string` | `null` | no |
| <a name="input_ip_configuration_name"></a> [ip\_configuration\_name](#input\_ip\_configuration\_name) | Name for the NIC IP configuration setting. | `string` | `null` | no |
| <a name="input_ip_forwarding_enabled"></a> [ip\_forwarding\_enabled](#input\_ip\_forwarding\_enabled) | Should IP Forwarding be enabled? | `bool` | `false` | no |
| <a name="input_key_vault_credential"></a> [key\_vault\_credential](#input\_key\_vault\_credential) | An key\_vault\_credential block as defined below. | <pre>object({<br>    name                     = string<br>    key_vault_url            = string<br>    service_principal_name   = string<br>    service_principal_secret = string<br>  })</pre> | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Location of the resource group to place the VM. | `string` | `"northcentralus"` | no |
| <a name="input_managed_identity_ids"></a> [managed\_identity\_ids](#input\_managed\_identity\_ids) | Specifies a list of User Assigned Managed Identity IDs to be assigned to this Windows Virtual Machine. | `list(string)` | `null` | no |
| <a name="input_managed_identity_type"></a> [managed\_identity\_type](#input\_managed\_identity\_type) | Specifies the type of Managed Service Identity that should be configured on this Windows Virtual Machine. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both). | `string` | `null` | no |
| <a name="input_nic_name"></a> [nic\_name](#input\_nic\_name) | Name of the network interface. | `string` | `null` | no |
| <a name="input_os_disk"></a> [os\_disk](#input\_os\_disk) | Provide a search on the image based on the details. | <pre>object({<br>    name                 = string<br>    caching              = string<br>    storage_account_type = string<br>    disk_size_gb         = optional(number)<br>  })</pre> | n/a | yes |
| <a name="input_ou_path"></a> [ou\_path](#input\_ou\_path) | An organizational unit (OU) within an Active Directory to place the virtual machines. | `string` | `"OU=Servers,OU=NP0,OU=NonProd,DC=agstar,DC=local"` | no |
| <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address) | The Static IP Address which should be used. This is valid only when `private_ip_address_allocation` is set to `Static` | `list(string)` | `null` | no |
| <a name="input_private_ip_address_allocation_type"></a> [private\_ip\_address\_allocation\_type](#input\_private\_ip\_address\_allocation\_type) | The allocation method used for the Private IP Address. Possible values are Dynamic and Static. | `string` | `"Dynamic"` | no |
| <a name="input_r_services_enabled"></a> [r\_services\_enabled](#input\_r\_services\_enabled) | Should R Services be enabled? | `bool` | `false` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group to place the VM's. | `string` | n/a | yes |
| <a name="input_source_image_reference"></a> [source\_image\_reference](#input\_source\_image\_reference) | Provide a search on the image based on the details. | <pre>object({<br>    publisher = string<br>    offer     = string<br>    sku       = string<br>    version   = string<br>  })</pre> | n/a | yes |
| <a name="input_sql_connectivity_port"></a> [sql\_connectivity\_port](#input\_sql\_connectivity\_port) | The SQL Server port | `number` | `1433` | no |
| <a name="input_sql_connectivity_type"></a> [sql\_connectivity\_type](#input\_sql\_connectivity\_type) | The connectivity type used for this SQL Server. Possible values are LOCAL, PRIVATE and PUBLIC | `string` | `"PRIVATE"` | no |
| <a name="input_sql_connectivity_update_password"></a> [sql\_connectivity\_update\_password](#input\_sql\_connectivity\_update\_password) | The SQL Server sysadmin login password. | `string` | n/a | yes |
| <a name="input_sql_connectivity_update_username"></a> [sql\_connectivity\_update\_username](#input\_sql\_connectivity\_update\_username) | The SQL Server sysadmin login to create. | `string` | n/a | yes |
| <a name="input_sql_instance"></a> [sql\_instance](#input\_sql\_instance) | A sql\_instance block as defined below. | <pre>object({<br>    adhoc_workloads_optimization_enabled = optional(bool)<br>    collation                            = optional(string)<br>    instant_file_initialization_enabled  = optional(bool)<br>    lock_pages_in_memory_enabled         = optional(bool)<br>    max_dop                              = optional(number)<br>    max_server_memory_mb                 = optional(number)<br>    min_server_memory_mb                 = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_sql_license_type"></a> [sql\_license\_type](#input\_sql\_license\_type) | The SQL Server license type. Possible values are AHUB (Azure Hybrid Benefit), DR (Disaster Recovery), and PAYG (Pay-As-You-Go). Changing this forces a new resource to be created. | `string` | `"PAYG"` | no |
| <a name="input_sql_virtual_machine_group_id"></a> [sql\_virtual\_machine\_group\_id](#input\_sql\_virtual\_machine\_group\_id) | The ID of the SQL Virtual Machine Group that the SQL Virtual Machine belongs to. | `string` | `null` | no |
| <a name="input_storage_configuration"></a> [storage\_configuration](#input\_storage\_configuration) | An storage\_configuration block as defined below. | <pre>object({<br>    disk_type                      = string<br>    storage_workload_type          = string<br>    system_db_on_data_disk_enabled = bool<br>    data_settings = object({<br>      default_file_path = string<br>      luns              = list(number)<br>    })<br>    log_settings = object({<br>      default_file_path = string<br>      luns              = list(number)<br>    })<br>    temp_db_settings = object({<br>      default_file_path      = string<br>      luns                   = list(number)<br>      data_file_count        = optional(number)<br>      data_file_size_mb      = optional(number)<br>      data_file_growth_in_mb = optional(number)<br>      log_file_size_mb       = optional(number)<br>      log_file_growth_mb     = optional(number)<br>    })<br>  })</pre> | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | ID of the subnet where the VM's reside. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags which should be assigned to this Virtual Machine. | `map(string)` | `{}` | no |
| <a name="input_virtual_machine_name"></a> [virtual\_machine\_name](#input\_virtual\_machine\_name) | The name of the virtual machine. | `string` | n/a | yes |
| <a name="input_virtual_machine_size"></a> [virtual\_machine\_size](#input\_virtual\_machine\_size) | The Virtual Machine SKU for the Virtual Machine. Refer: https://learn.microsoft.com/en-us/azure/virtual-machines/sizes to know more on different sizes available. | `string` | `"Standard_A2_v2"` | no |
| <a name="input_wsfc_domain_credential"></a> [wsfc\_domain\_credential](#input\_wsfc\_domain\_credential) | value | <pre>object({<br>    cluster_bootstrap_account_password = string<br>    cluster_operator_account_password  = string<br>    sql_service_account_password       = string<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_mssql_virtual_machine_id"></a> [mssql\_virtual\_machine\_id](#output\_mssql\_virtual\_machine\_id) | The ID of the MSSQL Virtual Machine |
| <a name="output_virtual_machine_id"></a> [virtual\_machine\_id](#output\_virtual\_machine\_id) | The ID of the Windows Virtual Machine |
