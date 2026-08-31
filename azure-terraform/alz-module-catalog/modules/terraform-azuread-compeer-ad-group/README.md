# terraform-azuread-compeer-ad-group

Entra ID security or Microsoft 365 group (`azuread_group`). Members and owners are
set inputs - changing membership **updates in place**, it never re-creates the
group. App-role assignments and PIM eligibility are out of scope.

## Usage

```hcl
module "admins" {
  source           = "../terraform-azuread-compeer-ad-group"
  display_name     = "sg-platform-admins"
  security_enabled = true
  members          = [module.identity.principal_id]
  owners           = [data.azuread_client_config.current.object_id]
}
```

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `display_name` | string | - | update in place |
| `security_enabled` | bool | `true` | |
| `mail_enabled` | bool | `null` | set with `mail_nickname` for M365 groups |
| `members` / `owners` | list/set(string) | `null` | update in place |
| `dynamic_membership` | object | `null` | `{enabled, rule}` - presence switches to dynamic membership |
| `assignable_to_role` | bool | `null` | ForceNew (role-assignable groups) |
| `visibility` | string | `null` | validated Private / Public / Hiddenmembership |

## Outputs

`id`, `object_id`, `display_name`.

## Lifecycle contract

| Change | Result |
|---|---|
| `members`, `owners`, `description`, `visibility`, most flags | **update in place** |
| add / remove the `dynamic_membership` block | update in place (switches membership model) |
| `assignable_to_role`, `onpremises_group_type` | **replace** (Azure ForceNew) |

State exposure: none.

## Migration

`security_enabled` default `null` -> `true` (azuread requires a security- or
mail-enabled group). Added `visibility` validation and `id` / `display_name`
outputs. Removed the dead `azuread_client_config` data source.

## Tests

`terraform test` (offline): security-group default, dynamic membership block,
visibility validation.
