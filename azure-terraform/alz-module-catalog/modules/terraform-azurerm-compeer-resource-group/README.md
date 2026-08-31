# terraform-azurerm-compeer-resource-group

A single `azurerm_resource_group`. Used by every platform pattern.

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | — | 1-90 chars, no trailing period (validated); ForceNew |
| `location` | string | — | ForceNew |
| `tags` | map(string) | `{}` | update in place |

## Outputs

`id`, `name`, `location`.

## Lifecycle contract

`tags` → **update in place**. `name` / `location` → **replace** (which deletes
every resource in the group — treat RG rename/move as a migration, never a
routine upgrade).

State exposure: none.

## Migration

Interface unchanged (7 consumers). Added name validation + descriptions.

## Tests

`terraform test` (offline): create, trailing-period rejection.
