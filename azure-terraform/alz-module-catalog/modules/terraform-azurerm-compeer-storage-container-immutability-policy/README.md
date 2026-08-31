# terraform-azurerm-compeer-storage-container-immutability-policy

A time-based immutability (WORM) policy on a caller-owned blob container.

## Contract

- Resource: `azurerm_storage_container_immutability_policy` (immutability policy).
- Inputs are explicitly typed; optional blocks are `optional(object(...))` and repeatables are `map(object(...))` keyed by a caller-stable name.
- Adjacent resource-group / network / RBAC / diagnostic capabilities are composed externally.

## Lifecycle

| Change | Effect |
|---|---|
| `immutability_period_in_days`, `protected_append_writes_enabled`, `protected_append_writes_all_enabled` | In-place update (while unlocked) |
| `locked` false -> true | In-place, and thereafter the period can only be extended |
| `storage_container_resource_manager_id` | Replace |

## State exposure

Outputs: policy `id`. No secrets.

## Migration

No breaking changes. Interface unchanged.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — create and attribute wiring; validation failures where the module adds `validation` / `precondition` rules.
