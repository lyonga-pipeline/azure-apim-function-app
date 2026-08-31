# platform-subscription-onboarding

Implementation workspace for the
[`subscription-onboarding`](../../../../patterns/terraform-azurerm-compeer-subscription-onboarding)
pattern.

## What it does

- Reads the management-group ID catalog from the `platform-governance` workspace
  (`use_tfe_outputs = true`), or takes it explicitly via `management_group_ids`.
- For each subscription in `onboarding.subscriptions` (all **already created by
  the CSP partner**, sitting under the Tenant Root Group):
  - moves it to `target_management_group_key` / `target_management_group_id`;
  - applies `onboarding.baseline_role_assignments` at subscription scope (skipped
    when the subscription sets `apply_baseline_rbac = false`);
  - applies that subscription's `app_role_assignments` at subscription scope.

It does **not** create subscriptions, resource groups, or workload resources.

## What it does NOT replace

| Concern | Workspace |
|---|---|
| MG hierarchy, MG-scope RBAC, custom roles, MG policy | `platform-governance` |
| Subscription creation | CSP partner (out of band) |
| Workload resources inside a subscription | that workload's workspace |

## Run order

`platform-governance` → **`platform-subscription-onboarding`** → platform /
workload workspaces (which now find their subscription in the right MG with
baseline RBAC already applied).

## Ops break-glass

If this workspace can't run but a subscription must be placed now:

```bash
../../../../patterns/terraform-azurerm-compeer-subscription-onboarding/scripts/move-subscription.sh \
  --subscription <SUB_GUID> --management-group <MG_NAME>
```

Then reconcile with `terraform plan` here.

## Identity / permissions

The workspace identity needs, at the Tenant Root Group (or the relevant MGs):
`Management Group Contributor` (to write subscription associations) and
`User Access Administrator` / `Owner` on the target subscriptions (to write role
assignments). Scope it down to the MG subtree Compeer actually onboards into.
