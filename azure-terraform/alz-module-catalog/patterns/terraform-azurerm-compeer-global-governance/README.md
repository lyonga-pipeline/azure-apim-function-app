# Global Governance Root

## Overview

**What this deploys:** the foundation everything else in this catalog builds
on top of — it runs first in the deployment order.

| Area | Resource / module | Purpose |
|---|---|---|
| Management groups | `module.management_groups` | The 25-entry go-live management-group tree under `compeer-enterprise-mg` (platform, workloads, internal/external/regulated apps, shared services, sandbox, decommissioned) |
| Policy definitions | `azurerm_policy_definition.definition` | Custom policy rules — both hand-authored (`var.custom_policy_definitions`) and the built-in landing-zone baseline (`policy_baseline.tf`, merged in) |
| Policy initiatives | `azurerm_policy_set_definition.initiative` | Packages related policy definitions into one assignable initiative — see "The policy baseline" below |
| Policy assignments | `azurerm_management_group_policy_assignment.mg_assignment`, `azurerm_subscription_policy_assignment.subscription_assignment` | Applies definitions/initiatives at a management-group or subscription scope |
| Custom roles + RBAC | `module.custom_role_definitions`, `module.role_assignments` | Custom Azure roles (kept minimal by design) and any standing role assignments declared here (rare — see `platform-authorization`) |
| Budgets | `azurerm_consumption_budget_management_group.management_group_budget` | MG-scope cost budgets |

**The policy baseline (`policy_baseline.tf`) — why it's not just 6 plain policy resources:**
this file exists because the deployable workspace needs real, working guardrails
out of the box (allowed regions, required tags, deny-public-PaaS, secure
storage, restrict public IP, private SQL) instead of an empty
`custom_policy_definitions = {}`. Two things about its shape are easy to miss
on a first read:

1. **It merges into the pattern's own variables, it doesn't add separate
   resources.** `local.pb_definitions` / `local.pb_assignments` are merged
   into `var.custom_policy_definitions` / the assignment map via
   `merge(var.x, local.pb_y)` in `main.tf` — so `var.custom_policy_definitions`
   still works for anything hand-authored on top, and the baseline is just
   more entries in the same `for_each` map, not a parallel code path.
2. **The 6 policies are packaged into one initiative, not 6 separate
   assignments.** `azurerm_policy_set_definition.initiative` bundles all 6
   under `compeer-landing-zone-baseline`, assigned once
   (`cmp-landing-zone-baseline`). This is what lets the *same* initiative be
   assigned again at a different management-group scope later (a future
   `regulated-apps-mg`, say) with its own parameter/`not_scopes` overrides,
   instead of re-declaring 6 policy assignments per scope every time the org
   adds one. Each member policy still gets its own effect/parameter wiring
   via the initiative's own declared parameters (ARM `[parameters('x')]`
   tokens in `parameter_values`) — so a future need for a policy-specific
   effect is additive (one more initiative parameter), not a rewrite.

`effect` defaults to `Audit` (see "Policy baseline" below for the toggle) —
promote to `Deny` per policy only after the false-positive review.

---

This root creates the management-group scaffold, Azure Policy assignments, and RBAC guardrails for the net-new landing-zone path.

It receives IDs explicitly from HCP workspace variables or an approved governance catalog. It does not read legacy remote state, infer subscription placement from environment names, or vend subscriptions. Subscription vending is handled by a separate enterprise process.

For a test tenant, leave `root_management_group_id` unset or blank. Terraform will create the top-level management groups directly under the tenant root. If you set `root_management_group_id`, the referenced parent management group must already exist in the same tenant and the HCP run identity must have permission to create children below it.

In HCP Terraform, set `root_management_group_id` as a Terraform workspace variable, not an environment variable. If you prefer an environment variable, its key must be `TF_VAR_root_management_group_id`. The value can be a management group name like `compeer-root`, a tenant-root management group GUID, or a full Azure management group resource ID such as `/providers/Microsoft.Management/managementGroups/compeer-root`. The root normalizes short names to the full Azure resource ID before passing them to AzureRM.

For a personal-account smoke test, prefer leaving `root_management_group_id` unset or blank unless you specifically want to create the landing-zone management groups under an existing parent management group. Do not set this to a subscription ID.

The error `Parent management group 'compeer-root' not found` means the configured parent ID does not exist in the Azure tenant used by the HCP workspace. Either create/import that parent first, or leave `root_management_group_id` unset or blank for the smoke test.

The root supports both individual Azure Policy definitions and policy set definitions/initiatives. Use policy set definitions for the baseline landing-zone initiative so approved regions, required tags, public access, encryption, diagnostics, identity, and connectivity guardrails can be assigned as one scoped package at the net-new landing-zone management group.

The checked-in management-group scaffold matches the current go-live diagram for the new enterprise tree: 25 management group entries under `compeer-enterprise-mg`. That includes platform, workloads, internal apps, external apps, regulated apps, shared services, sandbox, and decommissioned branches. The existing `compeer-mg` branch shown outside this tree is treated as an existing landing-zone path and is not created by this root.

### Policy baseline (`var.policy_baseline`)

The deny/audit baseline is shipped as code in `policy_baseline.tf` and toggled
with `var.policy_baseline` — set `enabled = true` and `management_group_key`
(the top LZ MG catalog key). It creates six custom policies (allowed regions,
required tags, deny-public-PaaS, secure storage, restrict public IP, private
SQL) plus the Microsoft Cloud Security Benchmark assignment.

**`effect` defaults to `Audit`** (runbook §2.4). Promote to `Deny` per policy
only after the false-positive review and once the exemption path
(`platform-policy` workspace) is live. `var.custom_policy_definitions` /
`var.management_group_policy_assignments` still work for anything hand-authored
on top. DeployIfNotExists remediation, exemptions, and RG-scoped assignments
live in the `platform-policy` pattern, not here.

The earlier checked-in `terraform.tfvars` (now `.example`) used `Deny` directly;
prefer `policy_baseline` with Audit-first for a fresh deployment.

This root is expected to pass the current OPA landing-zone workload policy because it deploys governance controls rather than workload/PaaS resources. Use Azure Policy for runtime guardrails and OPA for plan-time review of workload/platform deployment plans.

The Azure Policy required tag names are aligned with the platform tag module and OPA data file: `env`, `application`, `bt_owner`, `source_repo`, `tf_workspace`, `recovery`, `cost_center`, `data_classification`, and `compliance_boundary`.
