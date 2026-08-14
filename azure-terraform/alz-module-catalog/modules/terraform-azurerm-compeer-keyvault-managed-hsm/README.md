# Azure Key Vault Managed Hardware Security Module

This modules help to manage a Key Vault Managed HSM (Hardware Security Module). Managed HSM is a fully managed, highly available, single-tenant, and isolated service provided by Azure Key Vault. It provides cryptographic key storage and uses Hardware Security Modules to protect these keys.

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

## Modules

No modules.

---

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_managed_hardware_security_module.managed_hsm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_managed_hardware_security_module) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

### Resource Block

```hcl
resource "azurerm_key_vault_managed_hardware_security_module" "managed_hsm" {
  ...
}
```

This declares a resource of type `azurerm_key_vault_managed_hardware_security_module` with a local name `managed_hsm`.

#### Dynamic Network ACL Block

This block defines network access rules, determining which network or IP can access the Managed HSM.

```hcl
dynamic "network_acls" {
  ...
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_object_ids"></a> [admin\_object\_ids](#input\_admin\_object\_ids) | Specifies a list of administrators object IDs for the key vault Managed Hardware Security Module. Changing this forces a new resource to be created. | `list(string)` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Specifies the name of the Key Vault Managed Hardware Security Module. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the Key Vault Managed Hardware Security Module. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | The Name of the SKU used for this Key Vault Managed Hardware Security Module. Possible value is Standard\_B1. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | The Azure Active Directory Tenant ID that should be used for authenticating requests to the key vault Managed Hardware Security Module. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_network_acls"></a> [network\_acls](#input\_network\_acls) | A network\_acls block as defined below. | ```list(object({ bypass = string default_action = string }))``` | `[]` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether traffic from public networks is permitted. Defaults to true. Changing this forces a new resource to be created. | `bool` | `true` | no |
| <a name="input_purge_protection_enabled"></a> [purge\_protection\_enabled](#input\_purge\_protection\_enabled) | Is Purge Protection enabled for this Key Vault Managed Hardware Security Module? Changing this forces a new resource to be created. | `bool` | `false` | no |
| <a name="input_security_domain_key_vault_certificate_ids"></a> [security\_domain\_key\_vault\_certificate\_ids](#input\_security\_domain\_key\_vault\_certificate\_ids) | A list of KeyVault certificates resource IDs (minimum of three and up to a maximum of 10) to activate this Managed HSM. | `list(string)` | `[]` | no |
| <a name="input_security_domain_quorum"></a> [security\_domain\_quorum](#input\_security\_domain\_quorum) | Specifies the minimum number of shares required to decrypt the security domain for recovery. This is required when security\_domain\_key\_vault\_certificate\_ids is specified. Valid values are between 2 and 10. | `number` | `null` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 days. Defaults to 90. Changing this forces a new resource to be created. | `number` | `90` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. Changing this forces a new resource to be created. | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_key_vault_hsm_id"></a> [key\_vault\_hsm\_id](#output\_key\_vault\_hsm\_id) | The Key Vault Secret Managed Hardware Security Module ID. |
| <a name="output_key_vault_hsm_security_domain_encrypted_data"></a> [key\_vault\_hsm\_security\_domain\_encrypted\_data](#output\_key\_vault\_hsm\_security\_domain\_encrypted\_data) | This attribute can be used for disaster recovery or when creating another Managed HSM that shares the same security domain. |
| <a name="output_key_vault_hsm_uri"></a> [key\_vault\_hsm\_uri](#output\_key\_vault\_hsm\_uri) | The URI of the Key Vault Managed Hardware Security Module, used for performing operations on keys. |

---

## Conclusion

This Terraform configuration offers a comprehensive way to create and manage Azure's Key Vault Managed HSM, ensuring cryptographic keys are stored securely using Hardware Security Modules.