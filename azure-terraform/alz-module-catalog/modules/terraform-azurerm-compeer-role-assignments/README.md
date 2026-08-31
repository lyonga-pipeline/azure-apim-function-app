# terraform-azurerm-compeer-role-assignments

Bulk `azurerm_role_assignment` — a map of assignments keyed by a stable
caller-chosen key. Adding or removing a key affects only that assignment; the
others are never touched. **This is the platform's canonical RBAC module** (used
by every pattern) — its interface is a frozen contract.

## Usage

```hcl
module "kv_rbac" {
  source = "../terraform-azurerm-compeer-role-assignments"

  assignments = {
    app-secrets-user = {
      scope                = module.vault.id
      principal_id         = module.workload_identity.principal_id
      role_definition_name = "Key Vault Secrets User"
      principal_type       = "ServicePrincipal"
    }
  }
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `assignments` | map(object) | `{}` | key = stable logical name. Per entry: `scope`, `principal_id` (required); `role_definition_name` **xor** `role_definition_id` (validated); optional `name`, `principal_type`, `description`, `condition`, `condition_version`, `skip_service_principal_aad_check`, `delegated_managed_identity_resource_id` |

## Outputs

- `ids` — key → assignment resource ID
- `names` — key → assignment name (GUID)
- `assignments` — key → `{id, name, scope, principal_id, role_definition_id, role_definition_name, principal_type}`

## Lifecycle contract

| Change | Result |
|---|---|
| add / remove a key in `assignments` | create / destroy **only that assignment** (stable `for_each` keys) |
| `condition`, `description` on an existing assignment | update in place |
| `scope`, `principal_id`, `role_definition_*` on an existing assignment | **replace** that assignment (Azure ForceNew) — the key stays, the underlying assignment GUID changes |

State exposure: none.

## Migration

Interface unchanged (10 consumers). Only tests + docs added.

## Tests

`terraform test` (offline): create (name-based + id-based), additive add,
name-xor-id validation.
