# terraform-azurerm-compeer-subscription-onboarding

This pattern onboards subscriptions already created by the CSP partner. It does
not create subscriptions. For each configured subscription, it:

1. places the subscription under the required management group;
2. optionally creates approved subscription-scope RBAC assignments.

Management-group hierarchy, policy, Entra groups, custom roles, and
management-group RBAC are owned by their dedicated platform workspaces.

## Ownership

| Concern | Owner |
|---|---|
| Subscription creation | CSP partner |
| Management-group hierarchy and initial baseline | `platform-governance` |
| Additional policy assignments and exemptions | `platform-policy` |
| Entra groups, custom roles, and MG RBAC | `platform-authorization` |
| Subscription placement and exceptional subscription RBAC | This pattern |
| Resources inside the subscription | Platform or workload workspace |

## Policy behavior

This pattern does not create, delete, or exempt Azure Policy assignments.

When a subscription moves between management groups, Azure automatically stops
the policies inherited from the old hierarchy and applies policies inherited
from the new hierarchy. The onboarding code does not need to remove inherited
assignments.

A policy assigned directly to the subscription or one of its resource groups
is not inherited and remains after the move. Review those direct assignments
before onboarding. Any approved cleanup should be handled through a separate,
reviewed policy migration process, not this state.

## RBAC behavior

The Identity and RBAC design includes automated RBAC assignment in the
subscription onboarding lifecycle. It does not require every subscription to
receive a new direct assignment. The landing-zone design says RBAC should be
assigned at management-group scope wherever possible and inherited.

Prefer group-based RBAC assigned once at management-group scope and inherited by
subscriptions. Keep `baseline_role_assignments` and `app_role_assignments` empty
unless access must deliberately differ at subscription scope.

With both maps empty, the pattern creates no role assignments. The capability
remains available for a future approved exception without changing the module.
These inputs configure RBAC, not Azure Policy.

Each RBAC entry must set exactly one principal:

- `principal_group_key` for an Entra group published by `platform-authorization`;
- `principal_id` for an approved existing group, managed identity, or service
  principal.

Each entry must also set exactly one of `role_definition_name` or
`role_definition_id`. Direct user assignments are rejected.

## Inputs

| Name | Description |
|---|---|
| `management_group_ids` | Management-group IDs keyed by a stable catalog key. |
| `group_object_ids` | Entra group object IDs keyed by authorization catalog key. |
| `subscriptions` | Existing subscriptions keyed by a stable logical name. Each entry supplies its GUID and exactly one target MG key or ID. |
| `baseline_role_assignments` | Optional RBAC applied to every opted-in subscription. Prefer inherited MG RBAC instead. |

Each subscription can set `apply_baseline_rbac = false` and can provide keyed
`app_role_assignments`. Stable map keys prevent unrelated assignments from
being replaced when another entry is added.

## Example

```hcl
module "subscription_onboarding" {
  source = "../../patterns/terraform-azurerm-compeer-subscription-onboarding"

  management_group_ids = {
    connectivity = "/providers/Microsoft.Management/managementGroups/connectivity-mg"
  }

  subscriptions = {
    connectivity = {
      subscription_id             = "00000000-0000-0000-0000-000000000000"
      target_management_group_key = "connectivity"
    }
  }

  baseline_role_assignments = {}
  group_object_ids          = {}
}
```

## Lifecycle

| Change | Result |
|---|---|
| Add a subscription key | Places that subscription and creates its requested RBAC. |
| Change its target MG | Moves it to the new management group. |
| Add an RBAC map key | Adds only that keyed assignment. |
| Remove a subscription key | Removes the managed association and RBAC. Review this as a decommissioning change. |

## Outputs

- `subscription_placement_ids`
- `onboarded_subscription_ids`
- `onboarded_subscription_resource_ids`
- `subscription_target_management_group_ids`
- `baseline_role_assignment_ids`
- `app_role_assignment_ids`

## Permissions

The deployment identity needs permission to manage subscription placement on
the target management-group hierarchy. If subscription-scope RBAC is configured,
it also needs `Microsoft.Authorization/roleAssignments/write` at those
subscriptions.

## Tests

Run:

```bash
terraform init -backend=false
terraform test
```

Tests cover placement, ID normalization, baseline and app RBAC, opt-out behavior,
invalid subscription IDs, unknown management-group/group keys, and rejection of
direct user principals.

## Break-glass placement

For an urgent manual placement, use the idempotent helper and then reconcile the
workspace with `terraform plan`:

```bash
./scripts/move-subscription.sh --subscription <SUB_GUID> --management-group <MG_NAME> --dry-run
./scripts/move-subscription.sh --subscription <SUB_GUID> --management-group <MG_NAME>
```
