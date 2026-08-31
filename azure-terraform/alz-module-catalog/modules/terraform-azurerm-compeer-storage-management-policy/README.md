# terraform-azurerm-compeer-storage-management-policy

The single lifecycle-management (tiering / expiry) policy for a caller-owned storage account.

## Contract

- Resource: `azurerm_storage_management_policy` (lifecycle management policy).
- Inputs are explicitly typed; optional blocks are `optional(object(...))` and repeatables are `map(object(...))` keyed by a caller-stable name.
- Adjacent resource-group / network / RBAC / diagnostic capabilities are composed externally.

## Lifecycle

| Change | Effect |
|---|---|
| `rules` add/remove/retune (keyed `map(object)`) | In-place update |
| `storage_account_id` | Replace (one policy per account) |

## State exposure

Outputs: policy `id`. No secrets.

## Migration

No breaking changes. `rules` is a `map(object)` keyed by a caller-stable name so rule identity is stable across edits.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — create and attribute wiring; validation failures where the module adds `validation` / `precondition` rules.
