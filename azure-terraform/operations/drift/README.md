# Drift Governance

Drift management is implemented as a governance workflow, not a static report.

## Target Flow

```text
HCP drift event or scheduled drift check
  -> scheduled Azure DevOps governance scan
  -> query HCP Terraform workspaces and latest runs
  -> classify drift using drift-rules.yml
  -> resolve owner using workspace-owners metadata
  -> create or update Azure DevOps work item
  -> assign severity, due date, owner, and area path
  -> track remediation, exception, or closure
  -> publish monthly dashboard
```

## Files

| File | Purpose |
| --- | --- |
| `classification.md` | Drift categories, severity, SLA, and required fields |
| `drift-rules.yml` | Machine-readable first-pass classification rules |
| `workspace-owners.example.yml` | Workspace ownership and ADO area-path metadata |
| `drift-runbook.md` | Triage, work-item, remediation, and closure process |
| `drift-register-template.csv` | Register for detected drift items |
| `exception-register-template.csv` | Register for approved temporary exceptions |
| `scorecard-template.md` | Monthly dashboard structure |

## Automation Boundary

The approved Azure DevOps template should consume this folder's metadata and run the governance scan. This repo does not store the ADO pipeline template or secrets.

Required secure runtime values:

- `HCP_TOKEN`
- `ADO_PAT`
- `HCP_ORG`
- `ADO_ORG`
- `ADO_PROJECT`

## Work Item Behavior

The automation should create or update one Azure DevOps work item per workspace/resource/control combination. Existing open items should be updated instead of duplicated.

Each work item should include:

- workspace,
- HCP run ID/link,
- resource ID,
- classification rule,
- severity,
- SLA due date,
- owner,
- ADO area path,
- expected state,
- actual state,
- recommended remediation path.

