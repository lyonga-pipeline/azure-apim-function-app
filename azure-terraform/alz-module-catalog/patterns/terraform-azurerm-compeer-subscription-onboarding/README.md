# terraform-azurerm-compeer-subscription-onboarding

**Pattern module.** Subscriptions at Compeer are provisioned by the CSP partner,
not by Terraform. A freshly handed-over subscription lands under the **Tenant
Root Group**. This pattern takes those existing subscription GUIDs and, per
subscription:

1. **moves** it from the root group to its target management group, and
2. applies a **consistent baseline RBAC** set plus any **app-specific RBAC**, all
   at subscription scope.

It never creates subscriptions. Management-group creation and MG-scope RBAC stay
in [`global-governance`](../terraform-azurerm-compeer-global-governance). The old
[`subscription-vending`](../terraform-azurerm-compeer-subscription-vending)
pattern (which *does* create subscriptions) is retained for reference but is
**not deployed**.

## Composition

| Concern | Owned here | Owned elsewhere |
|---|---|---|
| MG hierarchy | — | `global-governance` |
| MG-scope RBAC / custom roles / policy | — | `global-governance` |
| Subscription creation | — | CSP partner (manual) |
| Root → target MG placement | ✅ `azurerm_management_group_subscription_association` | — |
| Subscription-scope baseline RBAC | ✅ `role-assignments` module | — |
| Subscription-scope app RBAC | ✅ `role-assignments` module | — |
| Resource groups / workloads inside the subscription | — | the workload's own workspace |

## Inputs

| Name | Description |
|---|---|
| `management_group_ids` | `map(string)` — resolved MG IDs keyed by catalog key (feed the governance workspace's `management_group_ids` output straight in). |
| `subscriptions` | `map(object)` keyed by a stable logical name. Each: `subscription_id` (GUID), exactly one of `target_management_group_key` / `target_management_group_id`, optional `display_name`, `workload` (Production/DevTest), `apply_baseline_rbac` (default true), `app_role_assignments` (keyed `map(object)`). |
| `baseline_role_assignments` | `map(object)` — RBAC applied at subscription scope to **every** subscription with `apply_baseline_rbac = true`. This is the "consistent way": platform ops, security readers, break-glass. |
| `default_tags` | Informational only (recorded on the contract marker). |

Each RBAC entry sets exactly one of `role_definition_name` / `role_definition_id`
(validated), plus `principal_id`, optional `principal_type`, `description`,
`condition` / `condition_version`.

## Lifecycle contract

| Change | Effect |
|---|---|
| Add a key to `subscriptions` | Places that subscription + applies baseline RBAC. Existing subscriptions untouched (stable `for_each` keys). |
| Change a subscription's `target_management_group_key` | Re-places that subscription into the new MG (in-place association update). |
| Remove a key from `subscriptions` | Destroys the association → **the subscription returns to the Tenant Root Group** and its baseline RBAC is removed. Deliberate — treat removals as decommissioning. |
| Add / change `baseline_role_assignments` | Fans out to every opted-in subscription. Assignment keys are `"<sub>::baseline::<name>"` so adding one baseline entry never disturbs the others. |
| Change `app_role_assignments` for one subscription | Only that subscription's app assignments change (keys `"<sub>::app::<name>"`). |

`azurerm_management_group_subscription_association` is not `ForceNew` on the MG —
moving between groups is an in-place update, not a replace.

## State exposure

No secrets. Outputs: `subscription_placement_ids`, `onboarded_subscription_ids`,
`onboarded_subscription_resource_ids`,
`subscription_target_management_group_ids`, `baseline_role_assignment_ids`,
`app_role_assignment_ids`.

## Break-glass / ops path

When this workspace cannot run but a subscription must be placed now, use
[`scripts/move-subscription.sh`](scripts/move-subscription.sh):

```bash
./scripts/move-subscription.sh --subscription <SUB_GUID> --management-group <MG_NAME> --dry-run
./scripts/move-subscription.sh --subscription <SUB_GUID> --management-group <MG_NAME>
```

It is idempotent (no-op if already placed). Run `terraform plan` afterwards; a
correctly placed subscription shows no diff.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — placement
wiring, baseline RBAC fan-out, unknown-MG-key precondition failure, GUID
validation.
