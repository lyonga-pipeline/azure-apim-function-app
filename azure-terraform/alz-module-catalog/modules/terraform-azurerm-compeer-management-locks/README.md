# terraform-azurerm-compeer-management-locks

Azure Resource Manager locks (`CanNotDelete` / `ReadOnly`) keyed by a stable
logical key.

This module is intentionally separate from management groups, resource groups,
and workload modules. Locks are an explicit lifecycle decision and can apply at
subscription, resource group, and individual resource scopes, so consuming
patterns should decide where locks belong.

Azure does not support applying resource locks directly to management groups.
Protect management groups with RBAC, PIM, approval process, and policy ownership
controls instead.

## Contract

Inputs are explicitly typed; repeatable configuration uses `map(object)` with
caller-stable keys. See `variables.tf` for the full surface and `outputs.tf`
for composition-ready IDs/attributes.

The module validates that every lock has a valid Azure lock level, a non-empty
scope, a non-empty name when a custom name is supplied, and that the scope is not
a management group ID.

## Inputs

`locks` is a map keyed by caller-stable logical names. Each lock supports:

- `name`: optional Azure lock name. Defaults to `<key>-lock`.
- `scope`: required Azure subscription, resource group, or resource ID.
- `lock_level`: optional lock level. Defaults to `CanNotDelete`.
- `notes`: optional notes passed to Azure.

`CanNotDelete` allows reads and updates but blocks deletion. In the Azure portal
this is shown as a Delete lock.

`ReadOnly` allows reads but blocks update and delete control-plane operations.
Use it carefully because it can block normal operations such as scaling,
diagnostic updates, RBAC changes, or other POST/PUT operations.

## Example

See `examples/basic` for a `CanNotDelete` lock on a platform resource group.

## Lifecycle

Configuration changes update in place unless the Azure resource marks the field
ForceNew (name / location / scope / parent). Adding or removing a map key affects
only that entry. Durable/state-bearing resources (workspaces, vaults, budgets,
management groups) must not be recreated by routine module upgrades.

State exposure: only where a secret input or sensitive output is documented in
`variables.tf` / `outputs.tf`.

## Migration

versions.tf standardised; descriptions and value validation added; `x == null || x.attr`
validation patterns fixed. Interface preserved for any consumed module.

## Tests

`terraform test` (offline, `mock_provider`): empty plan, default
`CanNotDelete`, explicit `CanNotDelete`, explicit `ReadOnly`, subscription /
resource group / resource scope pass-through, invalid lock level, empty name,
empty scope, and management group scope rejection.
