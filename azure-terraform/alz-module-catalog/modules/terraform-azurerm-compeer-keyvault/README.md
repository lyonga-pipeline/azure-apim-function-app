# Azure Key Vault

This module creates an Azure Key Vault, a service that allows the secure storage and management of secrets, keys, and certificates.In order to create assets for this vault please use the module terraform-azurerm-compeer-keyvault-assets module.

## ALZ catalog upgrade notes

This catalog copy keeps the Compeer module file layout and upgrades the implementation for enterprise landing-zone use:

- Uses `rbac_authorization_enabled` with a deprecated compatibility input for `enable_rbac_authorization`.
- Defaults purge protection to enabled and soft-delete retention to 90 days.
- Fixes the access policy dynamic block so each policy is expanded independently, and suppresses access policies when RBAC mode is enabled.
- Models network ACLs as a single object with private-first defaults.
- Adds optional certificate contacts and explicit outputs for name and RBAC mode.

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
| [azurerm_key_vault.keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

### Resource Block

```hcl
resource "azurerm_key_vault" "keyvault" {
  ...
}
```

This declares a resource of type `azurerm_key_vault` with a local name `keyvault`.

#### Dynamic Blocks

The `dynamic` blocks allow for more complex configurations based on input variables. This is especially useful when certain attributes might not be defined or if we might have multiple sets of values (like multiple data blocks for different DNS record types).

##### Dynamic Access Policy Block

This block defines permissions on the Key Vault, including tenant ID, object ID, application ID, and permissions for keys, secrets, certificates, and storage.

```hcl
dynamic "access_policy" {
  ...
}
```

##### Dynamic Network ACL Block

This block defines network access rules, determining which IP or virtual network can access the vault.

```hcl
dynamic "network_acls" {
  ...
}
```

#### Conditional Assignments

Throughout the resource block, patterns like the following are used:

```hcl
soft_delete_retention_days = var.soft_delete_retention_days
```

This ensures that attributes of the key vault are assigned based on provided input variables.

---


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | (Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | (Required) Specifies the name of the Key Vault.Changing this forces a new resource to be created. The name must be globally unique. If the vault is in a recoverable state then the vault will need to be purged before reusing the name. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The name of the resource group in which to create the Key Vault. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | (Required) The Name of the SKU used for this Key Vault. Possible values are standard and premium. | `string` | n/a | yes |
| <a name="input_access_policies"></a> [access\_policies](#input\_access\_policies) | Access policies for the key vault | ```list(object({ tenant_id = string object_id = string application_id = optional(string) key_permissions = list(string) secret_permissions = list(string) certificate_permissions = optional(list(string)) storage_permissions = optional(list(string)) }))``` | `null` | no |
| <a name="input_enable_rbac_authorization"></a> [enable\_rbac\_authorization](#input\_enable\_rbac\_authorization) | (Optional) Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions. | `bool` | `true` | no |
| <a name="input_enabled_for_deployment"></a> [enabled\_for\_deployment](#input\_enabled\_for\_deployment) | (Optional) Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault. | `bool` | `false` | no |
| <a name="input_enabled_for_disk_encryption"></a> [enabled\_for\_disk\_encryption](#input\_enabled\_for\_disk\_encryption) | (Optional) Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys. | `bool` | `false` | no |
| <a name="input_enabled_for_template_deployment"></a> [enabled\_for\_template\_deployment](#input\_enabled\_for\_template\_deployment) | (Optional) Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault. | `bool` | `false` | no |
| <a name="input_network_acls"></a> [network\_acls](#input\_network\_acls) | Network ACLs for the key vault | ```list(object({ default_action = string bypass = string ip_rules = list(string) virtual_network_subnet_ids = list(string) }))``` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | (Optional) Whether public network access is allowed for this Key Vault. Defaults to true. | `bool` | `false` | no |
| <a name="input_purge_protection_enabled"></a> [purge\_protection\_enabled](#input\_purge\_protection\_enabled) | (Optional) Is Purge Protection enabled for this Key Vault? | `bool` | `false` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | (Optional) The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days. | `number` | `7` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azure_key_vault_id"></a> [azure\_key\_vault\_id](#output\_azure\_key\_vault\_id) | The ID of the Key Vault. |
| <a name="output_azure_vault_uri"></a> [azure\_vault\_uri](#output\_azure\_vault\_uri) | The URI of the Key Vault, used for performing operations on keys and secrets. |

---

## Conclusion

This Terraform configuration provides a robust method to create and manage Azure Key Vaults, catering to various access and protection scenarios.
