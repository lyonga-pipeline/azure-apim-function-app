# terraform-azurerm-compeer-management-groups

Management-group hierarchy for ALZ foundations. The module creates top-level
management groups under either the supplied tenant/root parent or a per-group
external parent, then creates up to four child levels and optional subscription
associations.

Each management group is keyed by the desired management group ID. Stable keys
are important because they keep unrelated management groups from being replaced
when another group is added or removed.

## Contract

Inputs are explicitly typed; repeatable configuration uses `map(object)` with
caller-stable keys. See `variables.tf` for the full surface and `outputs.tf`
for composition-ready IDs/attributes.

The module validates that:

- only one parent model is used for each group,
- every `parent_key` points to another configured management group,
- a group cannot parent itself,
- the hierarchy fits the supported depth.

## Example

See `examples/basic` for an ALZ-style hierarchy under an existing tenant/root
management group.

## Lifecycle

Configuration changes update in place unless the Azure resource marks the field
ForceNew (name / location / scope / parent). Adding or removing a map key affects
only that entry. Durable/state-bearing resources (workspaces, vaults, budgets,
management groups) must not be recreated by routine module upgrades.

Deletion protection is not hidden inside this module. Management locks should be
created with `terraform-azurerm-compeer-management-locks` from the consuming
platform pattern, because locks are an explicit lifecycle decision and may apply
at management group, subscription, resource group, or resource scope.

State exposure: only where a secret input or sensitive output is documented in
`variables.tf` / `outputs.tf`.

## Migration

versions.tf standardised; descriptions and value validation added; `x == null || x.attr`
validation patterns fixed. Interface preserved for any consumed module.

## Tests

`terraform test` (offline, `mock_provider`): empty plan, two-level hierarchy,
externally parented top-level hierarchy, full supported depth, subscription
association, and invalid parent validation.
