# terraform-azurerm-compeer-budget

Consumption budget for a resource group, subscription or management group. `scope_type = null` (default) creates nothing. `contact_groups`/`contact_roles` are not sent to the management-group budget (provider limitation).

## Contract

Inputs are explicitly typed; repeatable configuration uses `map(object)` with
caller-stable keys. See `variables.tf` for the full surface and `outputs.tf`
for composition-ready IDs/attributes.

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

`terraform test` (offline, `mock_provider`): create / no-op, and key
validations & preconditions where present.
