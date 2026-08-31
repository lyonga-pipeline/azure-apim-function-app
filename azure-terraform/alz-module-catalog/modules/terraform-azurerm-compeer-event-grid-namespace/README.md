# terraform-azurerm-compeer-event-grid-namespace

An Event Grid namespace (MQTT / pull delivery) and optional namespace topics / subscriptions.

## Contract

- Resource: `azurerm_eventgrid_namespace` (namespace).
- Inputs are explicitly typed; optional blocks are `optional(object(...))` and repeatables are `map(object(...))` keyed by a caller-stable name.
- Adjacent resource-group / network / RBAC / diagnostic capabilities are composed externally.

## Lifecycle

| Change | Effect |
|---|---|
| `capacity`, `topic_spaces_configuration`, `inbound_ip_rules`, `public_network_access`, `tags` | In-place update |
| `sku` | In-place where Azure allows, otherwise Replace |
| `namespace_name`, `resource_group_name`, `location` | Replace |

## State exposure

Outputs: namespace `id` and topic/subscription IDs. No secrets output.

## Migration

No breaking changes. A stray `gitignore` file was removed.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — create and attribute wiring; validation failures where the module adds `validation` / `precondition` rules.
