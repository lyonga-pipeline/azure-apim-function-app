# OPA Policy Checks

This folder contains the HCP Terraform plan-time policy checks for the net-new landing-zone path. OPA is used before apply to catch unsafe Terraform plans. Azure Policy remains the runtime guardrail layer and is deployed from `landing-zones/net-new-hub-spoke/global-governance`.

## Folder Layout

| Path | Purpose |
| --- | --- |
| `policies.hcl` | HCP Terraform policy-set configuration. The default enforcement level is `advisory` for pilot rollout. |
| `data/net_new_lz.json` | Approved landing-zone policy data such as allowed regions, required tags, resource types, and approved TLS versions. |
| `policies/terraform_plan.rego` | Rego rules that inspect Terraform plan JSON and return `data.compeer.lz.deny` findings. |
| `tests/terraform_plan_test.rego` | Local unit tests for positive and negative plan examples. |

## Current Coverage

The current policy set is appropriate for the first advisory pilot. It validates:

- required enterprise tags on resources that expose `tags`,
- approved Azure regions,
- public IP creation,
- public network access on Storage, Key Vault, SQL Server, and App Service resources,
- Storage TLS, shared key, public blob, and infrastructure encryption posture,
- Key Vault RBAC, purge protection, and 90-day soft delete posture,
- SQL TLS and Microsoft Entra-only authentication posture,
- Function App and Web App HTTPS-only, public network, TLS, SCM TLS, and basic publishing auth posture,
- managed identity on Function App and Web App resources,
- diagnostic-setting presence for selected platform and workload resource types,
- module source checks that keep Terraform usage on approved HCP registry, pattern, or local module paths during the pilot.

The diagnostic rule intentionally checks for a diagnostic setting in the root composition, not exact one-to-one resource linkage. That keeps the first policy useful without creating false precision while the landing-zone pattern is still being piloted.

## Policy Input Contract

HCP Terraform evaluates OPA policies with Terraform plan data under `input.plan`. Local validation with `terraform show -json` usually passes the plan object directly. The policy supports both input shapes:

| Runtime | Resource changes path | Configuration path |
| --- | --- | --- |
| HCP Terraform OPA policy checks | `input.plan.resource_changes` | `input.plan.configuration.root_module` |
| Local raw Terraform plan JSON | `input.resource_changes` | `input.configuration.root_module` |

The Rego normalizes both shapes before evaluating resources and module sources. This is required for HCP advisory or mandatory findings to appear; reading only `input.resource_changes` makes HCP policy checks inspect an empty plan and can incorrectly show a clean pass.

## Pass and Advisory Conditions

The policy query is `data.compeer.lz.deny`. A clean result is an empty list. Any returned message is a policy finding.

Current pilot enforcement is `advisory`, so HCP Terraform allows the run to continue but displays findings under `Advisory warnings`. That is the expected enterprise pilot behavior: the control is visible, auditable, and reviewable without blocking early adoption.

Set `enforcement_level = "mandatory"` only after the findings have been remediated or approved through an exception workflow. In mandatory mode, any non-empty `data.compeer.lz.deny` result blocks the run.

Expected pass conditions:

- all tagged resources include the required enterprise tags: `env`, `application`, `bt_owner`, `source_repo`, `tf_workspace`, `recovery`, `cost_center`, `data_classification`, and `compliance_boundary`,
- resource locations are `eastus`, `eastus2`, `centralus`, or `global`,
- no public IP addresses are created without an approved exception,
- Storage Accounts do not enable public network access, shared access keys, public nested blob items, unsupported TLS, or disabled infrastructure encryption,
- Key Vaults do not enable public network access and keep RBAC authorization, purge protection, and 90-day soft delete retention enabled,
- SQL Servers do not enable public network access, keep TLS 1.2 or higher, and use Microsoft Entra-only authentication,
- Function Apps and Web Apps enforce HTTPS, approved TLS and SCM TLS, managed identity, disabled basic publishing authentication, and no public network access,
- required platform and workload resource types have a diagnostic setting created or updated in the root composition,
- module sources use approved HCP registry, pattern, or local module path prefixes.

Expected findings for the earlier ClientSync `np1` smoke posture included Storage Account public network access, Storage Account shared access keys, and missing diagnostic settings for required resource types. Those findings are acceptable during advisory pilot runs, but they should be remediated or formally excepted before mandatory enforcement or production use.

## Promoting Advisory Findings To Failures

The pilot policy is currently advisory in `policies.hcl`:

```hcl
policy "net-new-landing-zone-guardrails" {
  query             = "data.compeer.lz.deny"
  enforcement_level = "advisory"
}
```

When teams are familiar with the findings and remediation path, change only the enforcement level to make every non-empty `data.compeer.lz.deny` result fail the run:

```hcl
policy "net-new-landing-zone-guardrails" {
  query             = "data.compeer.lz.deny"
  enforcement_level = "mandatory"
}
```

Promotion checklist:

- update `azure-terraform/policies/opa/policies.hcl` from `advisory` to `mandatory`,
- keep the query as `data.compeer.lz.deny` unless the rules are intentionally split,
- run `opa test azure-terraform/policies/opa/policies azure-terraform/policies/opa/tests azure-terraform/policies/opa/data`,
- deploy the updated HCP policy set,
- rerun the target workspace plan and confirm there are zero mandatory failures,
- record any approved exceptions before widening scope.

If only some rules should become blocking first, split those rules into a separate mandatory policy query or a separate HCP policy set. With the current single-query structure, changing `enforcement_level` to `mandatory` promotes all findings in `data.compeer.lz.deny` at once.

## Policy Backlog

Before promotion to mandatory enforcement, add or refine:

- exact private endpoint requirement and target-resource matching,
- stronger module version checks for approved HCP registry usage once the final registry namespace/versioning convention is confirmed,
- workspace/environment naming alignment,
- production-only SKU/resiliency checks,
- managed identity requirement checks for additional resource types where the Azure resource supports it,
- CMK, backup, retention, and recovery-tier checks for regulated data services,
- exception-aware rules once the exception register schema is finalized.

## Local Validation

Install OPA locally or use an approved tool image, then run:

```bash
opa fmt -w azure-terraform/policies/opa/policies azure-terraform/policies/opa/tests
opa test azure-terraform/policies/opa/policies azure-terraform/policies/opa/tests azure-terraform/policies/opa/data
```

Expected result:

```text
PASS: 10/10
```

## HCP Enforcement Plan

Create one OPA policy set from this folder and scope it only to net-new landing-zone projects/workspaces.

Recommended first scopes:

- `ce-lz-governance`
- `ce-lz-platform`
- `ce-lz-workloads`

Do not attach this policy set organization-wide. Do not attach it to current or legacy landing-zone workspaces until those projects have completed advisory assessment, remediation planning, and exception review.

Rollout stages:

| Stage | Scope | Enforcement | Exit criteria |
| --- | --- | --- | --- |
| 1. Local validation | Policy repo only | Test-only | `opa test` passes and reviewers agree on rule intent. |
| 2. Pilot advisory | Net-new LZ HCP projects only | `advisory` | Findings are reviewed, false positives are removed, and exception workflow is tested. |
| 3. Non-prod blocking | Selected net-new non-prod workspaces | `mandatory` for high-confidence rules | One platform workspace and one workload workspace pass cleanly. |
| 4. Production blocking | Net-new production/path-to-production workspaces | `mandatory` | Production readiness checklist includes policy evidence and exception status. |
| 5. Legacy extension | Remediated current projects only | Per-domain rollout | Existing projects have state ownership, remediation backlog, and approved exception records. |

## HCP Creation Steps

The current automated path uses `azure-terraform/pipelines/azure-pipelines-opa-policy-code.yml`.

1. The validation stage runs `opa fmt` and `opa test`.
2. The deployment stage bundles `terraform_plan.rego` with `data/net_new_lz.json` into one individual HCP OPA policy.
3. The stage creates or updates one HCP OPA policy set and attaches the individual policy to it.
4. Optional `HCP_PROJECT_SCOPES` or `HCP_WORKSPACE_SCOPES` variables attach the policy set to net-new landing-zone targets.
5. Keep enforcement advisory during the pilot.
6. Promote selected rules to mandatory only after impact review and exception handling are operating.

This individual-policy mode avoids the VCS OAuth token ID and uploaded/versioned policy-set limits that can block test/free HCP organizations. VCS-backed policy sets remain valid for enterprise HCP plans that support them.

HCP Terraform supports policy sets scoped globally, by project, or by workspace. Use project/workspace scoping for the landing zone so current projects are isolated from new blocking controls.

## Automation Recommendation

Policy set creation is not a frequent daily activity, but it should still be automated or at least captured as idempotent configuration. The benefit is not speed; it is repeatability and auditability.

Recommended automation:

- store `policies.hcl`, Rego, data, and tests in VCS,
- create/update the HCP policy set through Terraform, HCP API, or a small bootstrap script,
- drive the target project/workspace list from `hcp/workspace-catalog.example.yaml` or its real catalog equivalent,
- run `opa test` in pull requests before policy changes are merged,
- keep enforcement-level promotion as a reviewed change tied to an exception/remediation decision.

Manual UI creation is acceptable for the first proof, but the final operating model should codify policy-set name, VCS path, scope, and enforcement level so the landing zone can be recreated consistently.

## References

- HCP Terraform policy enforcement overview: https://developer.hashicorp.com/terraform/cloud-docs/workspaces/policy-enforcement
- HCP Terraform OPA policy sets with VCS: https://developer.hashicorp.com/terraform/cloud-docs/workspaces/policy-enforcement/manage-policy-sets/opa-vcs
