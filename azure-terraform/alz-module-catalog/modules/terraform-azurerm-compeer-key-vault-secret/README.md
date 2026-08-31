# terraform-azurerm-compeer-key-vault-secret

Key Vault **secrets** only, created in a caller-owned vault. The vault, its
access policy / RBAC, private endpoints and diagnostics are owned elsewhere
(`keyvault`, `role-assignments`, `private-endpoint`, `diagnostic-settings`).

## Contract

- `secrets` is a `map(object)` keyed by a caller-stable logical name. The key is
  the identity Terraform tracks — renaming a key destroys and recreates that
  secret; the Azure secret `name` is a separate attribute.
- Each entry: `name`, `value` (sensitive), optional `content_type`,
  `not_before_date`, `expiration_date`, `tags`.
- `key_vault_id` is required and injected by the caller.

## Lifecycle

| Change | Effect |
|---|---|
| Add / remove a map key | Creates / destroys just that secret |
| `value`, `content_type`, `tags`, dates | In-place update, new secret version |
| `name` on an entry | Replace (new Azure secret) |
| `key_vault_id` | Replace all secrets |

## State exposure

Secret **values are stored in Terraform state** even though the input is
`sensitive`. Use an approved secret-delivery path for production secrets.
Outputs: `ids` (map key -> secret resource ID). No secret values are output.

## Migration

No breaking changes. Interface unchanged.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`) — create, no-op replan, add/remove
a map key. Run with `mock_provider`.
