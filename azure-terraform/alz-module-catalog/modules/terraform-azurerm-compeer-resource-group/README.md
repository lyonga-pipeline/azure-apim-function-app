# terraform-azurerm-compeer-resource-group

Creates one or more `azurerm_resource_group` resources from a keyed map.
Used by every platform pattern.

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `resource_groups` | map(object) | — | keyed resource groups; name/location validated; tags optional |

## Outputs

Primary outputs: `group_ids`, `group_names`, `group_locations`, all keyed by
the stable `resource_groups` input key.

Compatibility outputs: `id`, `name`, `location` for the group keyed as `main`.

## Lifecycle contract

`tags` update in place. `name` / `location` replace the resource group, which
deletes every resource in the group. Treat RG rename/move as a migration, never
a routine upgrade.

State exposure: none.

## Migration

Interface changed from a single `name` / `location` / `tags` input to keyed
`resource_groups`. Existing single-RG consumers should use the key `main`.
The module includes a `moved` block from the old single resource address to
`azurerm_resource_group.groups["main"]`.

## Tests

`terraform test` (offline): create, multi-group creation, output wiring, and
input validation.
