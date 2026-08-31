# terraform-azurerm-compeer-key-vault-key

Key Vault **keys** only, created in a caller-owned vault. Vault, RBAC, private
endpoints and diagnostics are owned elsewhere.

## Contract

- `keys` is a `map(object)` keyed by a caller-stable logical name.
- Each entry: `name`, `key_type` (RSA / RSA-HSM / EC / EC-HSM), `key_opts`,
  optional `key_size`, `curve`, `not_before_date`, `expiration_date`,
  `rotation_policy`, `tags`.
- `key_vault_id` is required and injected by the caller.

## Lifecycle

| Change | Effect |
|---|---|
| Add / remove a map key | Creates / destroys just that key |
| `key_opts`, dates, `rotation_policy`, `tags` | In-place update |
| `name`, `key_type`, `key_size`, `curve` | Replace |
| `key_vault_id` | Replace all keys |

## State exposure

Key material is generated in the HSM/vault and never leaves it; state holds
metadata and IDs only. Outputs: `ids` (map key -> key resource ID).

## Migration

No breaking changes. Interface unchanged.

## Tests

`terraform test` — create, no-op replan, add/remove a map key.
