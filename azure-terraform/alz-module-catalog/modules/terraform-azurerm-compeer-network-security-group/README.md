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

An empty combined rule collection explicitly sets `security_rule=[]`, removing
all custom inline rules while preserving Azure's built-in defaults. This fixes
the previous dynamic-block behavior, which could retain old rules when the last
configured rule was removed. It also removes manually added custom rules: this
module is the sole inline-rule owner, not an NSG shell for external rule owners.
Review existing-state plans before upgrading, especially when both inputs are empty.
Publish a new registry release before selecting this behavior in HCP consumers;
do not overwrite an existing tag. The resource address and input/output interfaces
are unchanged.

State exposure: none.

## Migration

Interface unchanged (2 consumers). Added `priority` / `access` / `direction`
validation on `security_rules`. Removed the dead `azurerm_client_config` data
source.

## Tests

`terraform test` (mocked): create, additive rule add, bad-priority rejection,
explicit last-rule removal preserving the NSG ID, and the legacy rule-list input.
