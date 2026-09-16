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

## Overview

**What this deploys:** the bridge between a CSP-handed-over subscription (in
the Tenant Root Group) and the management-group tree `global-governance`
already created — MG placement + subscription-scope RBAC, nothing else.

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
| `group_object_ids` | `map(string)` — Entra security group object IDs keyed by `platform-authorization.rbac_groups` key. Used to resolve `principal_group_key` in RBAC entries. |
| `subscriptions` | `map(object)` keyed by a stable logical name. Each: `subscription_id` (GUID), exactly one of `target_management_group_key` / `target_management_group_id`, optional `display_name`, `workload` (Production/DevTest), `apply_baseline_rbac` (default true), `app_role_assignments` (keyed `map(object)`). |
| `baseline_role_assignments` | `map(object)` — RBAC applied at subscription scope to **every** subscription with `apply_baseline_rbac = true`. This is the "consistent way": platform ops, security readers, break-glass. |
| `legacy_policy_removals` | `map(object)` — legacy subscription/resource-group-scope policy **assignments** to remove during onboarding. See "Legacy policy removal" below. |
| `default_tags` | Informational only (recorded on the contract marker). |

Each RBAC entry sets exactly one of `role_definition_name` / `role_definition_id`
(validated), and exactly one of `principal_group_key` / `principal_id`.
`principal_group_key` is preferred for human/team access because the platform
model is **User -> Entra group -> Azure role -> scope**. `principal_id` remains
available for approved pre-existing workload groups, managed identities, or
service principals. Direct `principal_type = "User"` is rejected.

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

## Legacy policy removal

**The problem.** A CSP-handed-over subscription sits under the Tenant Root
Group and may carry Azure Policy assignments — inherited from the root/old
parent MG, or assigned directly at the subscription or a resource group inside
it. Moving the subscription to its new landing-zone MG (above) is native Azure
behaviour and handles the **inherited** kind automatically and immediately:
Azure enforces single-MG membership, so the moment the subscription leaves the
old MG, its policies stop applying, and the new landing-zone MG's policies
start applying instead. Nothing in Terraform needs to do anything extra for
that part.

What Azure does **not** do on its own is remove a policy assignment made
**directly** at the subscription or a resource group inside it — that kind of
assignment isn't inherited from any MG, so it isn't affected by which MG the
subscription belongs to. It stays attached and keeps evaluating alongside the
new landing-zone baseline unless it's explicitly deleted.

**The mechanism — two-phase import then destroy.** `var.legacy_policy_removals`
lets you bring one of these into Terraform state so its removal is a normal,
reviewable plan/apply instead of a manual `az policy assignment delete`:

1. In the Portal, open the legacy subscription (before or during onboarding)
   and find the assignment: its **name**, its **scope** (the subscription
   itself, or a specific resource group), and its **Definition** link (a
   policy or an initiative — `policy_definition_id` takes either, Azure uses
   the same field for both).
2. Add an entry to `legacy_policy_removals`, e.g.:
   ```hcl
   legacy_policy_removals = {
     old_tag_policy = {
       subscription_key     = "hub"                # a key in var.subscriptions
       scope_type           = "subscription"        # or "resource_group"
       # resource_group_name = "rg-example"          # required if scope_type = "resource_group"
       assignment_name      = "legacy-tag-policy"
       policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/<guid>"
     }
   }
   ```
3. **Import.** `import` blocks can only live in a root module, so they are
   declared in the *consuming workspace*, not here — see
   `implementations/platform-lz/workspaces/platform-subscription-onboarding/main.tf`'s
   "Legacy policy assignment removal — import blocks" section for the
   reference implementation. Run `terraform apply`: Terraform imports the
   assignment into state. Because this pattern also declares the resource
   with the same real arguments, this first apply is a no-op — no destroy yet.
4. **Remove.** Delete the entry from `legacy_policy_removals` (or the whole
   map, once done). The next `terraform plan` shows a clean, reviewable
   destroy of exactly that assignment. Apply it once you've checked the plan.

This is deliberately two separate applies — importing and destroying in the
same run would make a destroy of something this pattern never created look
like just another part of the diff, instead of a distinct, reviewed step.

`legacy_policy_removals[*].subscription_key` must match a key in
`var.subscriptions`; this cross-check runs as a `terraform_data.onboarding_contract`
precondition rather than a variable `validation` block, because Terraform
(before 1.9) only allows a variable's own `validation` block to reference
that same variable — not `var.subscriptions`. See the `contract_valid` local
for how the existing MG-key and principal-group-key checks already use this
pattern.

## State exposure

No secrets. Outputs: `subscription_placement_ids`, `onboarded_subscription_ids`,
`onboarded_subscription_resource_ids`,
`subscription_target_management_group_ids`, `baseline_role_assignment_ids`,
`app_role_assignment_ids`, `legacy_policy_removal_ids`.

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
validation, and `legacy_policy_removals` validation (invalid `scope_type`,
missing `resource_group_name`, unknown `subscription_key`). The `import`
blocks themselves are **not** covered by these tests — import requires a real
provider read against a real API-shaped resource ID, which `mock_provider` has
no equivalent for; that mechanism can only be verified against a real
subscription.
