# HCP Variable Set Model

The new landing-zone path should separate shared platform inputs from workload-owned configuration.

## Enterprise Variable Sets

`vs-azure-tenant`

- `tenant_id`
- `default_location`
- `allowed_locations`

`vs-lz-standards`

- `required_tags`
- `environment_catalog`
- `policy_enforcement_stage`
- `module_registry_namespace`

## Authentication Variable Sets

Use separate auth variable sets by environment class. Prefer workload identity federation where available.

`vs-azure-auth-nonprod`

- non-prod client or federated identity settings
- sensitive values marked sensitive in HCP

`vs-azure-auth-prod`

- production client or federated identity settings
- restricted to production platform/workload operators

## Platform Shared Output Variable Sets

These values are produced by platform workspaces or approved catalogs and consumed by workload roots.

`vs-platform-shared-np`

- `log_analytics_workspace_id`
- `action_group_id`
- `subnet_ids`
- `private_dns_zone_ids`

Workload roots should pass those IDs explicitly into modules. Reusable modules should not derive subscription IDs, subnet IDs, DNS zones, or workspace IDs from environment names.

## Sensitive Data

Do not place application secrets in committed `tfvars`. Use HCP sensitive variables, approved secret stores, or a dedicated secrets workflow. Terraform may create stable secret objects when approved, but secret values should come from secure runtime input.

