# Azure Network Security Group

This Terraform module creates an Azure Network Security Group with optional inline security rules. It is intentionally scoped to the NSG resource so subnet association, route intent, diagnostics, policy, and RBAC can be composed by platform or workload patterns.

## Reusability and Extensibility

This module is designed as a reusable resource building block for Compeer platform and workload patterns:

- Resource-scoped ownership: the module models the NSG resource boundary, not a subnet, virtual network, or workload solution.
- Pattern-ready interface: network placement, subnet association, diagnostics, and RBAC stay in the consuming pattern/root.
- Optional rule surface: callers may provide no rules, legacy list-based rules, or preferred keyed-map rules.
- Stable identity for repeatable configuration: the preferred `security_rules` input uses stable map keys, reducing unrelated churn when a rule is added or removed.
- Lifecycle-aware defaults: callers provide the NSG name, resource group, and location explicitly, avoiding hidden naming or placement decisions.
- Composition-ready outputs: the module exports the NSG ID, name, resource group, and rule state for downstream association and diagnostic modules.
- Backward-compatible growth: the legacy `security_rule` list input remains supported, while new consumers should use `security_rules`.

Subnet association should be handled by the dedicated association module or by a pattern/root module so subnet and NSG lifecycles remain distinct.

## Usage

```hcl
module "network_security_group" {
  source = "../"

  name                = "nsg-platform-hub-prod-eastus2"
  resource_group_name = "rg-platform-connectivity-prod-eastus2"
  location            = "eastus2"

  security_rules = {
    allow_https_inbound = {
      name                       = "Allow-Https-Inbound"
      description                = "Allow HTTPS from corporate networks."
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.0.0.0/8"
      destination_address_prefix = "*"
    }
  }

  tags = {
    environment = "prod"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Network Security Group name. | `string` | n/a | yes |
| `resource_group_name` | Existing resource group name where the NSG is deployed. | `string` | n/a | yes |
| `location` | Azure region for the NSG. | `string` | n/a | yes |
| `security_rules` | Preferred keyed map of NSG security rules. Keys should be stable rule identities. | `map(object)` | `{}` | no |
| `security_rule` | Backward-compatible list of NSG security rules. Prefer `security_rules` for new consumers. | `list(object)` | `[]` | no |
| `tags` | Tags to assign to the NSG. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Network Security Group resource ID. |
| `network_security_group_id` | Network Security Group resource ID. |
| `name` | Network Security Group name. |
| `resource_group_name` | Resource group containing the NSG. |
| `network_security_group_rules` | Security rules applied to the NSG. |
