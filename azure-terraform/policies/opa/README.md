# OPA Policy Checks

These policies are intended for HCP Terraform policy sets attached to net-new landing-zone projects.

Start with advisory behavior during the pilot. Promote to blocking only after:

- one platform workspace and one workload workspace pass cleanly,
- exception handling is operating,
- policy owners agree on override process,
- and current projects remain excluded from blocking scope.

## Test Locally

If OPA is installed:

```bash
opa test azure-terraform/policies/opa/policies azure-terraform/policies/opa/tests azure-terraform/policies/opa/data
```

## HCP Attachment

Attach these policies to:

- `ce-lz-governance`
- `ce-lz-platform`
- `ce-lz-workloads`

Do not attach them as blocking policy sets to legacy/current projects until those projects are remediated.
