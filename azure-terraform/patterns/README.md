# Terraform Composition Patterns

Patterns compose narrow Terraform 2.0 base and companion modules into approved workload shapes.

Base modules still own one primary Azure resource lifecycle. Pattern modules own a curated composition contract for common workload deployments. They are allowed to orchestrate dependencies, but they should not hide subscription, subnet, DNS, policy, or ownership decisions.

## Available Patterns

| Pattern | Purpose |
| --- | --- |
| `function-app` | Reference Function App workload composition with App Service Plan, identity, storage, Key Vault, App Insights, private endpoints, diagnostics, RBAC, and alerting. |

## Design Rules

- Dependencies use explicit `create` or `existing` modes.
- Existing dependencies require explicit IDs and names needed by downstream modules.
- Network placement uses explicit subnet IDs and Private DNS zone IDs from platform outputs or approved catalogs.
- RBAC, diagnostics, private endpoints, and alerts remain visible in the pattern contract.
- Production deployments must not disable private connectivity, diagnostics, or monitoring without an approved exception.
- Broad `ignore_changes` for app settings is not part of the pattern.

