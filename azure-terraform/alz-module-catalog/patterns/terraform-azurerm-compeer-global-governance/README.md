# Global Governance Root

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
