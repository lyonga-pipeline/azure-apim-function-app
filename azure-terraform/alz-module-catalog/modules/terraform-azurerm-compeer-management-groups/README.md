# terraform-azurerm-compeer-management-groups

Management-group hierarchy module for ALZ foundations. It creates the management
groups that belong to the new landing-zone branch, then optionally places
subscriptions into those groups.

For the Compeer ALZ design this means the module should start at
`compeer-enterprise-mg`. It should not create the tenant root group, and it
should not recreate an existing legacy landing-zone branch such as `compeer-mg`.

Each management group is keyed by the desired Azure management group name/ID.
The key is also used as the default display name, so a key such as
`security-mg` will display as `security-mg` unless `display_name` is explicitly
overridden. Stable keys are important because they keep unrelated management
groups from being replaced when another group is added or removed.

## Contract

Inputs are explicitly typed; repeatable configuration uses `map(object)` with
caller-stable keys. See `variables.tf` for the full surface and `outputs.tf`
for composition-ready IDs/attributes.

The module only models management groups and subscription association. Policy,
RBAC, locks, and tag enforcement belong in governance/pattern modules so each
capability has its own lifecycle and can be tested independently.

The module validates that:

- only one parent model is used for each group,
- every `parent_key` points to another configured management group,
- a group cannot parent itself,
- the hierarchy fits the supported depth.

## Inputs

### `root_parent_management_group_id`

Optional default Azure parent for top-level groups. Use a full management group
resource ID when the new hierarchy must be created under an existing parent.

If this value is `null`, top-level groups are placed directly under the tenant
root group.

Example:

```hcl
root_parent_management_group_id = "/providers/Microsoft.Management/managementGroups/tenant-root"
```

### `management_groups`

Map of management groups keyed by the Azure management group name/ID.

Each entry supports:

- `display_name`: optional display name. Defaults to the map key.
- `parent_key`: optional key of another management group in the same map.
- `parent_management_group_id`: optional full resource ID of an existing
  external parent. Use this only for top-level groups that need a specific
  external parent.
- `subscription_ids`: optional set of subscription resource IDs to associate
  with the management group.

Set only one of `parent_key` or `parent_management_group_id` on each group.

Direct module use:

```hcl
module "management_groups" {
  source = "app.terraform.io/Compeer-Financial-Services/compeer-management-groups/azurerm"

  management_groups = {
    "compeer-enterprise-mg" = {}

    "platform-mg" = {
      parent_key = "compeer-enterprise-mg"
    }

    "security-mg" = {
      parent_key = "platform-mg"
    }
  }
}
```

Pattern use:

The `terraform-azurerm-compeer-global-governance` pattern accepts
`parent_key = "root"` as a convenience for top-level groups. The pattern
converts that value to `null` before calling this module. The base module itself
does not require a real management group named `root`.

```hcl
governance = {
  management_groups = {
    "compeer-enterprise-mg" = {
      parent_key = "root"
    }
  }
}
```

## Hierarchy Levels

The module creates management groups in ordered layers so Terraform can build
the parent/child tree without self-referencing module instances.

- `root`: top-level groups with no `parent_key`. In the Compeer design this is
  `compeer-enterprise-mg`.
- `level_1`: direct children of top-level groups, such as `platform-mg`,
  `workloads-mg`, `sandbox-mg`, and `decommissioned-mg`.
- `level_2`: children below those groups, such as `security-mg`,
  `identity-mg`, `management-mg`, `connectivity-mg`, `internal-apps-mg`, and
  `external-apps-mg`.
- `level_3`: environment or workload grouping layers, such as
  `internal-apps-dev-mg` or `external-apps-prod-mg`.
- `level_4` and `level_5`: optional deeper layers for future hierarchy needs.

`level_5` is not a required deployment layer. It is only used when the input map
contains a management group whose parent chain reaches that depth. If the ALZ
hierarchy stops at `level_3`, the `level_4` and `level_5` resources have empty
`for_each` maps and deploy nothing.

## Example

See `examples/basic` for an ALZ-style hierarchy under an existing tenant/root
management group.

## Outputs

The module exposes composition-ready values for downstream policy, RBAC, locks,
and subscription placement:

- `management_group_ids`: resource IDs keyed by management group key.
- `management_group_names`: Azure names keyed by management group key.
- `management_groups`: ID, name, display name, and parent ID for each group.
- `subscription_association_ids`: subscription-association IDs keyed by
  management group and subscription.

Consumers should use these outputs instead of reconstructing management group
IDs in downstream modules.

## Lifecycle

Configuration changes update in place unless the Azure resource marks the field
ForceNew (name / location / scope / parent). Adding or removing a map key affects
only that entry. Durable/state-bearing resources (workspaces, vaults, budgets,
management groups) must not be recreated by routine module upgrades.

Deletion protection is not hidden inside this module. Management locks should be
created with `terraform-azurerm-compeer-management-locks` from the consuming
platform pattern, because locks are an explicit lifecycle decision and may apply
at management group, subscription, resource group, or resource scope.

State exposure: only where a secret input or sensitive output is documented in
`variables.tf` / `outputs.tf`.

## Migration

Earlier versions split top-level groups between `root` and `external_parent`
resource blocks. The current module uses one top-level `root` resource block and
lets either `root_parent_management_group_id` or per-group
`parent_management_group_id` set the Azure parent. This removes ambiguity while
keeping the interface stable for consumers.

## Tests

`terraform test` (offline, `mock_provider`): empty plan, two-level hierarchy,
externally parented top-level hierarchy, `root_parent_management_group_id`
default, full supported depth (five child levels), subscription association, and
invalid parent / excessive depth validation.
