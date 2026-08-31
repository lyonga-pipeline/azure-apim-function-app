# terraform-azurerm-compeer-key-vault-certificate

Key Vault **certificates** only (self-signed / issuer-issued policy, or import),
created in a caller-owned vault. Vault, RBAC, private endpoints and diagnostics
are owned elsewhere.

## Contract

- `certificates` is a `map(object)` keyed by a caller-stable logical name.
- Each entry carries either a `certificate` (import) block or a
  `certificate_policy` block, plus optional `tags`.
- `key_vault_id` is required and injected by the caller.

## Lifecycle

| Change | Effect |
|---|---|
| Add / remove a map key | Creates / destroys just that certificate |
| `tags` | In-place update |
| `certificate_policy`, `certificate`, `name` | Replace (new certificate) |
| `key_vault_id` | Replace all certificates |

## State exposure

Imported PFX/PEM contents and passwords are held in Terraform state. Prefer
policy-issued certificates. Outputs: `ids` (map key -> certificate resource ID).

## Migration

No breaking changes. Interface unchanged.

## Tests

`terraform test` — create, no-op replan, add/remove a map key.
