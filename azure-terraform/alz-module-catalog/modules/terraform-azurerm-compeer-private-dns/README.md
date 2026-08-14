# Azure Private DNS Zones and Virtunal Network Link

This modules create Private DNS Zones and Virtual Network Link

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
| [azurerm_private_dns_zone.private_dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.private_dns_zone_virtual_network_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the Private DNS Zone. Must be a valid domain name. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Specifies the resource group where the resource exists. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_virtual_network_id"></a> [virtual\_network\_id](#input\_virtual\_network\_id) | The ID of the Virtual Network that should be linked to the DNS Zone. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_vnet_link_name"></a> [vnet\_link\_name](#input\_vnet\_link\_name) | The name of the Private DNS Zone Virtual Network Link. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_private_dns_zone_tags"></a> [private\_dns\_zone\_tags](#input\_private\_dns\_zone\_tags) | value | `map(string)` | `{}` | no |
| <a name="input_registration_enabled"></a> [registration\_enabled](#input\_registration\_enabled) | Is auto-registration of virtual machine records in the virtual network in the Private DNS zone enabled? | `bool` | `false` | no |
| <a name="input_soa_record"></a> [soa\_record](#input\_soa\_record) | value | ```list(object({ email = string expire_time = optional(number) minimum_ttl = optional(number) refresh_time = optional(number) retry_time = optional(number) ttl = optional(number) tags = optional(map(string)) }))``` | `[]` | no |
| <a name="input_vnet_link_tags"></a> [vnet\_link\_tags](#input\_vnet\_link\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_dns_zone_id"></a> [private\_dns\_zone\_id](#output\_private\_dns\_zone\_id) | The Private DNS Zone ID. |
| <a name="output_private_dns_zone_virtual_network_link"></a> [private\_dns\_zone\_virtual\_network\_link](#output\_private\_dns\_zone\_virtual\_network\_link) | The ID of the Private DNS Zone Virtual Network Link. |
