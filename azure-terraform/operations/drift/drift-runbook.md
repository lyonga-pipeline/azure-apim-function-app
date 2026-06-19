# Drift Runbook

## Detection

Use HCP drift detection for net-new landing-zone workspaces. For workspaces not yet onboarded, run scheduled read-only plans and record findings in the drift register.

The target operating pattern is:

```text
HCP drift event or scheduled drift check
  -> scheduled Azure DevOps governance scan
  -> query HCP Terraform workspaces and latest runs
  -> classify drift using drift-rules.yml
  -> resolve owner from workspace-owners.example.yml or approved catalog
  -> create or update Azure DevOps work item
  -> assign severity, owner, area path, and due date
  -> track remediation, exception, or closure
  -> publish monthly dashboard
```

The scheduled scan should run daily for production and critical platform workspaces. Weekly is acceptable for early non-production pilot workspaces until the process is stable.

Required secure runtime variables for the automation are:

- `HCP_TOKEN`
- `ADO_PAT`
- `HCP_ORG`
- `ADO_ORG`
- `ADO_PROJECT`

These values belong in approved secure variable stores. They should not be committed to the repo.

## Triage

1. Confirm the changed resource and workspace boundary.
2. Resolve workspace owner and ADO area path using `workspace-owners.example.yml` or the approved workspace catalog.
3. Classify the drift using `drift-rules.yml` and `classification.md`.
4. Create or update an Azure DevOps work item with severity, due date, owner, HCP run link, and resource ID.
5. Decide whether the change must be reverted, codified, imported, moved to another owner, or excepted.
6. Create remediation child items sized to five working days or less when the fix is larger than one work item.

## Remediation Paths

| Path | When to use |
| --- | --- |
| Revert in Azure | Unauthorized change creates risk and Terraform already has the desired config |
| Codify in Terraform | Change is valid and should become the desired state |
| Import into state | Resource belongs in the workspace but was created outside Terraform |
| Move ownership | Resource belongs in another workspace or platform layer |
| Exception | Temporary variance is approved with expiry and owner |

## Azure DevOps Work Item Expectations

Drift automation should create or update one active work item per workspace/resource/control combination. Avoid duplicate work items for the same drift condition.

Minimum fields:

| Field | Value |
| --- | --- |
| Title | `Terraform drift detected: <workspace> - <resource/control>` |
| Description | Workspace, HCP run ID/link, resource ID, category, severity, expected state, actual state, recommended action |
| Area path | From workspace ownership metadata |
| Assigned to | Workspace owner or platform owner |
| Priority | Derived from severity |
| Due date | Detection date plus SLA days |
| Tags | `TerraformDrift`, severity, environment, category |

The work item remains open until the plan is clean, an exception is approved, or ownership has moved to the correct workspace/team.

## Closure Criteria

A drift item is closed only when:

- HCP plan is clean or expected,
- exception is approved and dated,
- ownership is confirmed,
- and evidence is linked in the register.
