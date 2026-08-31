# Azure Private Endpoint

This module creates an Azure Private Endpoint, which enables private IP connectivity from Virtual Networks to Azure Platform as a Service (PaaS) services. This provides a more secure method of allowing virtual machines (VMs) in the VNet to access the Azure services over the Azure backbone network, eliminating exposure to the public internet.

## Reusability and Extensibility

This module is designed as a reusable resource building block for Compeer platform and workload patterns:

- Resource-scoped ownership: the module models the Azure resource boundary, not a single application, environment, or landing-zone root.
- Pattern-ready interface: enterprise decisions such as naming, network placement, diagnostics, RBAC, private endpoints, and policy posture stay in the consuming pattern or root.
- Optional capability surface: optional Azure features are exposed through typed inputs, objects, maps, and empty defaults so consumers can enable them without forking the module.
- Stable identity for repeatable configuration: repeatable nested configuration uses keyed maps where identity matters, reducing unrelated replacement when an item is added or removed.
- Lifecycle-aware defaults: inputs favor provider-supported in-place updates and avoid generated names, positional indexes, or hidden defaults that create unnecessary replacement.
- Composition-ready outputs: IDs, names, endpoint details, and other downstream attributes are exported so dependent modules and HCP workspaces do not need to reconstruct implementation details.
- Backward-compatible growth: new capabilities should be added with optional inputs and sensible defaults; breaking input or output changes should be versioned deliberately.
- Validation focus: consumers should test create, no-change plan, in-place updates, optional feature add/remove, expected replacement cases, and destroy behavior before broad reuse.

Module-specific extension points: Private service connection, DNS zone group, IP configurations, edge zone, NIC naming, and timeouts are optional inputs so the same module supports Key Vault, Storage, Web, SQL, and other Private Link services.

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
### Module contract principles

- The module owns only the lifecycle stated in its architecture classification; adjacent RG/network/RBAC/private-endpoint/diagnostic/extension capabilities are composed externally unless explicitly classified as a pattern module.
- Optional capabilities use `null`, `{}` or typed optional objects/maps rather than magic empty strings or implicit creation side effects.
- Repeatable caller-owned instances must use stable logical keys; callers should not depend on list index identity.
- Secrets supplied to Terraform remain part of Terraform state even when marked sensitive; use HCP sensitive variables or an approved secret-delivery pattern.
- Provider ranges are bounded. Widen provider constraints only after create/no-change/update/upgrade/replacement lifecycle tests pass.
