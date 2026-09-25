# platform-subscription-onboarding

Implementation workspace for the
[`subscription-onboarding`](../../../../patterns/terraform-azurerm-compeer-subscription-onboarding)
pattern.

## What it does

- Reads the management-group ID catalog from the `platform-governance` workspace
  (`use_tfe_outputs = true`), or takes it explicitly via `management_group_ids`.
- Reads Entra RBAC group object IDs from the `platform-authorization` workspace
  only when a baseline/app RBAC entry uses `principal_group_key`.
- For each subscription in `onboarding.subscriptions` (all **already created by
  the CSP partner**, sitting under the Tenant Root Group):
  - moves it to `target_management_group_key` / `target_management_group_id`;
  - applies `onboarding.baseline_role_assignments` at subscription scope (skipped
    when the subscription sets `apply_baseline_rbac = false`);
  - applies that subscription's `app_role_assignments` at subscription scope.

It does **not** create subscriptions, resource groups, or workload resources.
It also does not create or remove policy assignments. Moving a subscription
changes its inherited management-group policies automatically. Direct
subscription/resource-group assignments remain and must be reviewed through a
separate policy migration process.

## What it does NOT replace

| Concern | Workspace |
|---|---|
| MG hierarchy and initial baseline | `platform-governance` |
| Additional policy assignments and exemptions | `platform-policy` |
| Entra groups, custom roles, and MG-scope RBAC | `platform-authorization` |
| Subscription creation | CSP partner (out of band) |
| Workload resources inside a subscription | that workload's workspace |

## Run order

`platform-governance` → **`platform-subscription-onboarding`** → platform /
workload workspaces (which now find their subscription in the right MG with
baseline RBAC already applied).

`platform-authorization` is not a prerequisite when both RBAC maps are empty,
as they are for the initial four platform-subscription placements. Deploy it
before onboarding configurations that resolve any `principal_group_key`.

Management-group IDs, subscription GUIDs, and Entra object IDs are deliberately
declassified at the pattern boundary. They are Azure identifiers, not secrets;
this prevents HCP output sensitivity from making Terraform `for_each` keys
invalid. Authentication credentials remain sensitive.

Subscription-scope RBAC is optional. Prefer assigning common access once at
management-group scope in `platform-authorization` and inheriting it. Populate
the onboarding RBAC maps only for approved subscription-specific exceptions.
The design requires RBAC automation capability during onboarding, but it does
not require direct RBAC on every subscription. Empty RBAC maps create no role
assignments.

## Where subscription IDs belong

Subscription IDs are identifiers, not credentials. Keep the subscription map,
including IDs and target management-group keys, in the reviewed
`terraform.tfvars` deployment configuration. HCP workspace variables should be
reserved for authentication, sensitive values, and values that must differ
without a code change. Replace all example GUIDs before the live apply.

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
