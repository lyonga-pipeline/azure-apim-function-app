# Operations

This directory holds the operating model that supports the new landing-zone IaC path after the Terraform code exists.

The first required routines are:

- drift classification and triage,
- workspace ownership mapping,
- automated drift work-item creation,
- exception registration,
- policy violation review,
- evidence capture,
- workspace ownership review,
- and recurring backlog grooming for module, policy, and landing-zone improvements.

Drift management should operate as a governance pipeline:

```text
HCP drift event or scheduled drift check
  -> scheduled governance scan
  -> query HCP workspaces and latest runs
  -> classify drift using rules
  -> create or update Azure DevOps work item
  -> assign owner, severity, and SLA
  -> track remediation, exception, or closure
  -> publish monthly dashboard
```

CI/CD templates are intentionally not stored here. The drift folder defines the operating model, metadata, classification rules, and work-item expectations that an approved Azure DevOps template can consume.
