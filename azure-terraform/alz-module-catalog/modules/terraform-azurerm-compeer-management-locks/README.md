# terraform-azurerm-compeer-management-locks

Management locks (`CanNotDelete` / `ReadOnly`) keyed by a stable logical key.

This module is intentionally separate from management groups, resource groups,
and workload modules. Locks are an explicit lifecycle decision and can apply at
many Azure scopes, so consuming patterns should decide where locks belong.

## Contract

Inputs are explicitly typed; repeatable configuration uses `map(object)` with
caller-stable keys. See `variables.tf` for the full surface and `outputs.tf`
for composition-ready IDs/attributes.

The module validates that every lock has a non-empty scope and a valid Azure
lock level.

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

`terraform test` (offline, `mock_provider`): empty plan, lock creation, invalid
lock level validation, and empty-scope validation.
