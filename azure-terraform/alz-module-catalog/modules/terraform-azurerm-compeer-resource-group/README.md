# terraform-azurerm-compeer-resource-group

Creates one or more `azurerm_resource_group` resources from a keyed map.
Used by every platform pattern.

## Naming Validation

Validation stays in this resource module. Names must satisfy Azure's character/
length rules, be unique case-insensitively, and contain an approved region and
environment token separated by a hyphen or underscore:

- Regions: `cus`, `ncus`.
- Spoke environments: `prod`, `dev`, `test`, `uat`, `np1`, `np2`, `np3`,
  `sandbox`, `sbx`.
- Existing registry tokens retained: `np0`, `dev-test`.

Example: `orders-cus-sandbox-network-rg`. The module validates names; it does not
generate or rewrite them. The spoke's naming module still handles generation,
and its `sbx` input generates the established `sandbox` naming/tag token.
Supporting a token here does not automatically enable it in every calling pattern.

The installed Compeer RG release 1.0.0 already enforced the region/environment
rule but omitted test/sandbox/sbx. This change extends that allowlist without
changing resource addresses or the deployed registry's existing restrictions.
The earlier catalog source was more permissive: consumers of that source with
nonconforming names must review the new constraint before upgrading. Do not
rename deployed RGs to make validation pass.

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

## Registry Release

1. Update the registry module source. When applying this to Compeer's existing
   module, only `variables.tf` needs the validation fix; keep its supplied
   `azurerm_resource_group.groups` block and outputs unchanged.
2. Test, then publish a NEW approved HCP module version. Do not replace the
   existing 1.0.0 tag or assume pushing this catalog automatically publishes to
   the separate Compeer module registry.
3. Keep the blueprint's existing registry source:
   `app.terraform.io/Compeer-Financial-Services/compeer-base-resource-group/azurerm`.
   Bump its exact `version` to the published release. For example, use 1.0.1 only
   if that version is newly published and approved, not as an assumed release.
4. Run `terraform init -backend=false` and `terraform test` in the blueprint.
   If an environment consumes an HCP-published blueprint, also publish a new
   blueprint release and update that environment's blueprint pin.
5. Review a real enabled plan. The module label, map keys, names, provider and
   `azurerm_resource_group.groups` implementation are unchanged by this fix;
   no state move is expected. Stop on unexpected RG deletion or replacement.

The corrected naming predicate is:

```hcl
can(regex("(?i)(^|[-_])(cus|ncus)[-_](prod|dev|test|uat|np0|np1|np2|np3|dev-test|sandbox|sbx)([-_]|$)", group.name))
```

Tests include all eleven approved/legacy tokens, output/resource identity,
rejected prefixes, unapproved regions/environments, and the existing input guards.
Mock tests do not prove live Azure permissions or private registry publication.
