# Azure Private Endpoint

This module creates an Azure Private Endpoint, which enables private IP connectivity from Virtual Networks to Azure Platform as a Service (PaaS) services. This provides a more secure method of allowing virtual machines (VMs) in the VNet to access the Azure services over the Azure backbone network, eliminating exposure to the public internet.

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
| [azurerm_private_endpoint.private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

### Resource Block

```hcl
resource "azurerm_private_endpoint" "private_endpoint" {
  ...
}
```

This declares a resource of type `azurerm_private_endpoint` with a local name `private_endpoint`.

#### Dynamic Blocks

The `dynamic` blocks provide a flexible way to iterate over a collection of items to produce nested configuration blocks.

##### Dynamic Private Service Connection Block

This block defines a private link service connection, specifying the resource and the target subresource.

```hcl
dynamic "private_service_connection" {
  ...
}
```

##### Dynamic Private DNS Zone Group Block

This block associates the private endpoint with specific DNS zone groups.

```hcl
dynamic "private_dns_zone_group" {
  ...
}
```

##### Dynamic IP Configuration Block

This block specifies the IP configuration for the private endpoint.

```hcl
dynamic "ip_configuration" {
  ...
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Specifies the name of the Private Endpoint. | `string` | `""` | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the Private Endpoint. | `string` | `""` | yes |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the resource exists. | `string` | `""` | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The ID of the subnet in which the private endpoint will reside. | `string` | `""` | yes |
| <a name="input_custom_network_interface_name"></a> [custom\_network\_interface\_name](#input\_custom\_network\_interface\_name) | (Optional) Specifies the name of the Network Interface used for this Private Endpoint. | `string` | `null` | no |
| <a name="input_private_service_connections"></a> [private\_service\_connections](#input\_private\_service\_connections) | Specifies the private link service connection configurations. | `list` | `[]` | yes |
| <a name="input_private_dns_zone_group"></a> [private\_dns\_zone\_group](#input\_private\_dns\_zone\_group) | (Optional) Specifies the associated private DNS zone configurations. | `list` | `[]` | no |
| <a name="input_ip_configurations"></a> [ip\_configurations](#input\_ip\_configurations) | (Optional) Specifies the IP configurations for the private endpoint. | `list` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the resource. | `map` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_endpoint_id"></a> [private\_endpoint\_id](#output\_private\_endpoint\_id) |The ID of the Private Endpoint. |

---

## Conclusion

This Terraform configuration provides a streamlined method to create and manage Azure Private Endpoints. It ensures private connectivity from VMs in VNet to Azure PaaS services, enhancing security by eliminating public internet exposure.