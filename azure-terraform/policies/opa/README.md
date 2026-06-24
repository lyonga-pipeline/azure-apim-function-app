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
- diagnostic-setting presence for selected platform and workload resource types.

The diagnostic rule intentionally checks for a diagnostic setting in the root composition, not exact one-to-one resource linkage. That keeps the first policy useful without creating false precision while the landing-zone pattern is still being piloted.

## Policy Backlog

Before promotion to mandatory enforcement, add or refine:

- exact private endpoint requirement and target-resource matching,
- module source/version checks for approved HCP registry usage,
- workspace/environment naming alignment,
- production-only SKU/resiliency checks,
- managed identity requirement checks where the resource type supports it,
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
PASS: 6/6
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

1. Connect HCP Terraform to the VCS repository that contains this folder.
2. Create an OPA policy set using `azure-terraform/policies/opa` as the policy set directory.
3. Use `policies.hcl` as the policy configuration file.
4. Attach the policy set to the net-new landing-zone HCP projects or explicit workspace list.
5. Keep `enforcement_level = "advisory"` during the pilot.
6. Promote selected rules to `mandatory` only after impact review and exception handling are operating.

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
