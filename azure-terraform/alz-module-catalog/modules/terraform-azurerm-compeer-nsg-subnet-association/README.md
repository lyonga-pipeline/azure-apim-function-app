# terraform-azurerm-compeer-nsg-subnet-association

Associates one NSG to one subnet
(`azurerm_subnet_network_security_group_association`). Both IDs are
caller-supplied. Single-association module — compose with `for_each` at the
pattern layer.

## Inputs

| Input | Type | Notes |
|---|---|---|
| `subnet_id` | string | ForceNew |
| `network_security_group_id` | string | update in place |

## Outputs

`id`.

## Lifecycle contract

`network_security_group_id` change → update in place; `subnet_id` change →
replace. Only one NSG per subnet.

State exposure: none.

## Tests

`terraform test` (offline): create.
