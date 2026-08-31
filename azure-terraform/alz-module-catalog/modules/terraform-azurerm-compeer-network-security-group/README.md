# terraform-azurerm-compeer-network-security-group

A single NSG with inline security rules. Rules are a `map(object)` keyed by a
stable name (`security_rules`); a legacy `security_rule` list input is still
accepted and merged. Subnet association is `nsg-subnet-association`.

> Do **not** also manage rules for this NSG with standalone
> `azurerm_network_security_rule` resources elsewhere — inline + standalone on the
> same NSG causes a perpetual diff.

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | — | ForceNew |
| `security_rules` | map(object) | `{}` | key = stable name; `priority` 100-4096, `access` Allow/Deny, `direction` Inbound/Outbound (validated) |
| `security_rule` | list(object) | `[]` | backward-compatible; merged with `security_rules` |
| `tags` | map(string) | `{}` | update in place |

## Outputs

`id` (+ `network_security_group_id` alias), `name`, `resource_group_name`,
`network_security_group_rules`.

## Lifecycle contract

All rule add/edit/remove and `tags` → **update in place** (inline rules).
`name` / `resource_group_name` / `location` → **replace**.

State exposure: none.

## Migration

Interface unchanged (2 consumers). Added `priority` / `access` / `direction`
validation on `security_rules`. Removed the dead `azurerm_client_config` data
source.

## Tests

`terraform test` (offline): create, additive rule add, bad-priority rejection.
