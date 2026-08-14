# Azure Network Security Group with Dynamic Security Rule

This Terraform module creates an Azure Network Security Group (NSG) with dynamic security rules. Network Security Groups in Azure provide a way to centralize and standardize network-based security rules for network resources within an Azure Virtual Network.

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

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_group.network_security_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |

### Resource Block

```hcl
resource "azurerm_network_security_group" "network_security_group" {
  ...
}
```

This declares a resource of type `azurerm_network_security_group` with a local name `network_security_group`.

#### Dynamic Security Rule Block

The `dynamic "security_rule"` block allows for defining dynamic security rules based on input variables. This can be particularly useful for scenarios where you want to dynamically control the rules that get applied to the NSG based on certain conditions.

```hcl
dynamic "security_rule" {
  ...
}
```

---

## Inputs

Here are the main input variables for the module:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Specifies the name of the Network Security Group. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the Network Security Group. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the Network Security Group should be deployed. | `string` | n/a | yes |
| <a name="input_security_rule"></a> [security\_rule](#input\_security\_rule) | A list of security rule configurations that define the behavior of the Network Security Group. Each rule is represented as an object with multiple attributes (e.g., name, description, protocol, etc.). | `list(object({...}))` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Specifies a set of tags to associate with the Network Security Group. | `map(string)` | `{}` | no |

The `security_rule` input is a list of objects, each representing a security rule configuration. The attributes of each object include parameters such as `name`, `description`, `protocol`, and so on, reflecting the attributes in the provided Terraform configuration.

---

## Outputs

Depending on your specific use case, you might want to provide outputs for the Network Security Group ID, its rules, or other attributes. For instance:

| Name | Description |
|------|-------------|
| <a name="output_network_security_group_id"></a> [network\_security\_group\_id](#output\_network\_security\_group\_id) | The ID of the Network Security Group created by the module. |
| <a name="output_network_security_group_rules"></a> [network\_security\_group\_rules](#output\_network\_security\_group\_rules) | A list of security rules applied to the Network Security Group. |

---

## Example Usage

To provide context for how to use this module, you can include an example like the following:

```hcl
module "azure_nsg" {
  source              = "./path-to-module-directory"
  name                = "my-nsg"
  resource_group_name = "my-resource-group"
  location            = "West Europe"
  security_rule       = [
    {
      name         = "AllowSSH"
      description  = "Allows SSH access."
      protocol     = "Tcp"
      source_port_range = "*"
      destination_port_range = "22"
      source_address_prefix  = "10.0.0.0/8"
      destination_address_prefix = "*"
      access      = "Allow"
      priority    = 100
      direction   = "Inbound"
    },
    ...
  ]
  tags = {
    environment = "production"
  }
}
```

This is a basic example to illustrate the module's usage. Adjust as needed for your own infrastructure requirements.