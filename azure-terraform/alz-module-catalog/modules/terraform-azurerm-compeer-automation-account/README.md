# terraform-azurerm-compeer-automation-account

Azure Automation account (`azurerm_automation_account`) only. Runbooks,
schedules, DSC configurations, modules, variables and connections are managed
by the consuming pattern.

## Contract

- Required: `name`, `resource_group_name`, `location`.
- `sku_name` validated (`Basic` / `Free`).
- Optional typed blocks: `identity`, `encryption`; optional scalars
  `local_authentication_enabled`, `public_network_access_enabled`, `timeouts`.

## Lifecycle

| Change | Effect |
|---|---|
| `sku_name`, `local_authentication_enabled`, `public_network_access_enabled`, `identity`, `tags` | In-place update |
| `name`, `resource_group_name`, `location` | Replace |
| `encryption` key source | In-place update |

## State exposure

Outputs: `id`, `name`, `identity`, `dsc_server_endpoint`,
`dsc_primary_access_key` / `dsc_secondary_access_key` (**sensitive** — present
in state). Prefer managed identity over the DSC keys where possible.

## Migration

- `public_network_access_enabled` default changed **`true` -> `false`** (private by default). Pair with a Private Endpoint, or set `true` explicitly.

No breaking changes. Interface unchanged.

## Tests

`terraform test` — create + attribute wiring.
