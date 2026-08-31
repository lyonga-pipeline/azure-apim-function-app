# Azure App Service Environment (ASE) and ASE v3 Terraform Module

This Terraform module provides the resources to create an Azure App Service Environment (ASE) or ASE v3 which acts as a fully isolated, highly scalable hosting service for Azure App Services.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.11, < 4.0 |

---

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.67.0 |

---

## Resources

| Name | Type |
|------|------|
| [azurerm_app_service_environment.app_service_environment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_environment) | resource |
| [azurerm_app_service_environment_v3.service_environment_v3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_environment_v3) | resource |

### Resource Blocks

#### ASE v2

```hcl
resource "azurerm_app_service_environment" "app_service_environment" {
  ...
}
```

This declares a resource of type `azurerm_app_service_environment` with a local name `app_service_environment`.

#### ASE v3

```hcl
resource "azurerm_app_service_environment_v3" "service_environment_v3" {
  ...
}
```

This declares a resource of type `azurerm_app_service_environment_v3` with a local name `service_environment_v3`.

---

## Inputs

### Common Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the App Service Environment. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource_group_name](#input\_resource\_group\_name) | The name of the Resource Group where the App Service Environment exists. Defaults to the Resource Group of the Subnet (specified by subnet_id). Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet_id](#input\_subnet\_id) | The ID of the Subnet which the App Service Environment should be connected to. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_cluster_setting"></a> [cluster_setting](#input\_cluster\_setting) | Cluster settings for Azure App Service Environment. | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_create_v3"></a> [create_v3](#input\_create\_v3) | Boolean to determine whether to create ASE v3. | `bool` | `false` | no |

### None V3 Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_internal_load_balancing_mode"></a> [internal_load_balancing_mode](#input\_internal\_load\_balancing\_mode) | Specifies which endpoints to serve internally in the Virtual Network for the App Service Environment. | `string` | n/a | no |
| <a name="input_pricing_tier"></a> [pricing_tier](#input\_pricing\_tier) | The pricing tier for the App Service Environment. | `string` | n/a | no |
| <a name="input_front_end_scale_factor"></a> [front_end_scale_factor](#input\_front\_end\_scale\_factor) | Scale factor for front end instances. | `number` | `[]` | no |
| <a name="input_allowed_user_ip_cidrs"></a> [allowed_user_ip_cidrs](#input\_allowed\_user\_ip\_cidrs) | Allowed user added IP ranges on the ASE database. Use the addresses you want to set as the explicit egress address ranges. | `set(string)` | `[]` | no |

### V3 Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_new_private_endpoint_connections"></a> [allow_new_private_endpoint_connections](#input\_allow\_new\_private\_endpoint\_connections) | Should new Private Endpoint Connections be allowed. | `bool` | `false` | no |
| <a name="input_dedicated_host_count"></a> [dedicated_host_count](#input\_dedicated\_host\_count) | This ASEv3 should use dedicated Hosts. | `number` | `null` | no |
| <a name="input_zone_redundant"></a> [zone_redundant](#input\_zone\_redundant) | Set to true to deploy the ASEv3 with availability zones supported. Zonal ASEs can be deployed in some regions. Note: You can only set either dedicated_host_count or zone_redundant but not both. Changing this forces a new resource to be created. | `bool` | `false` | no |
| <a name="input_internal_load_balancing_mode_v3"></a> [internal_load_balancing_mode_v3](#input\_internal\_load\_balancing\_mode\_v3) | Specifies which endpoints to serve internally in the Virtual Network for the App Service Environment. | `string` | n/a | yes |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="app_service_environment_id"></a> [app_service_environment_id](#output\_app\_service\_environment\_id) | The ID of the App Service Environment. |
| <a name="app_service_environment_id_v3"></a> [app_service_environment_id_v3](#output\_app\_service\_environment\_id\_v3) | The ID of the App Service Environment v3. |

---

For further details and examples, please refer to the [official documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_environment) and [ASE v3 documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_environment_v3).

### Module contract principles

- The module owns only the lifecycle stated in its architecture classification; adjacent RG/network/RBAC/private-endpoint/diagnostic/extension capabilities are composed externally unless explicitly classified as a pattern module.
- Optional capabilities use `null`, `{}` or typed optional objects/maps rather than magic empty strings or implicit creation side effects.
- Repeatable caller-owned instances must use stable logical keys; callers should not depend on list index identity.
- Secrets supplied to Terraform remain part of Terraform state even when marked sensitive; use HCP sensitive variables or an approved secret-delivery pattern.
- Provider ranges are bounded. Widen provider constraints only after create/no-change/update/upgrade/replacement lifecycle tests pass.
