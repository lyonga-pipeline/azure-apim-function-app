# terraform-azurerm-compeer-application-insights

A single azurerm_application_insights. Pair with a Log Analytics workspace via `workspace_id` (classic AI is retired).

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

AzureRM >= 4.81 and < 5 is required. The module keeps the existing inverse input
names daily_data_cap_notifications_disabled, disable_ip_masking and
local_authentication_disabled for caller compatibility, but maps them to the
provider's non-deprecated *_enabled attributes. Null/false preserve enabled
defaults; true disables the corresponding feature. The resource address/name
and local_authentication_disabled output contract are unchanged. This is not a
provider-v5 upgrade of the wider catalog. Consumers pinned to an older AzureRM
lock file must review an init -upgrade and the resulting plan before applying.

## Tests

`terraform test` (offline, `mock_provider`): create / no-op, and key
validations & preconditions where present.
