# Platform ALZ Implementation

`implementations/platform-lz` is a workspace catalog, not a deployable Terraform root.

Each platform lifecycle boundary is deployed from an individual root under `workspaces/` and mapped to its own HCP Terraform workspace. This matches the IaC delivery strategy: ownership, state, approval, drift, recovery, and blast radius stay scoped to the platform domain being changed.

The roots still reuse the common pattern modules under `../../patterns`. The AVM/HCP improvements are fitted into those patterns, so the separated workspaces compose the same reusable implementation instead of copying standalone AVM stacks.

## Workspace Roots

```text
workspaces/platform-governance
workspaces/platform-subscriptions
workspaces/platform-policy
workspaces/platform-management
workspaces/platform-connectivity
workspaces/platform-identity-security
workspaces/platform-hybrid-connectivity
workspaces/platform-palo-alto
workspaces/platform-directory-services
workspaces/platform-cloudflare-connectors
workspaces/platform-shared-services
workspaces/platform-workload-spoke
workspaces/platform-network-peering
workspaces/platform-cloudflare-edge
```

Each root has its own `terraform.tfvars.example` and should be attached to a distinct HCP Terraform workspace working directory.

## Dependency Model

Dependent roots consume approved outputs with the HCP Terraform `tfe_outputs` data source, or through explicit IDs supplied as workspace variables. Do not use broad remote-state access for normal dependencies.

Examples:

- `platform-connectivity` can read `platform-management.log_analytics_workspace_id` for diagnostics.
- `platform-policy` can read `platform-governance.management_group_ids` for policy definitions and assignments.
- `platform-identity-security` can read `platform-management.log_analytics_workspace_id` and `platform-connectivity.private_dns_zone_ids`.
- `platform-hybrid-connectivity` can read `platform-connectivity.subnet_ids["GatewaySubnet"]`.
- `platform-directory-services` can read `platform-connectivity.subnet_ids` and `platform-management.log_analytics_workspace_id`.
- `platform-cloudflare-connectors` can read the connector subnet from `platform-connectivity` and monitoring outputs from `platform-management`.
- `platform-shared-services` can read hub VNet and Private DNS outputs from `platform-connectivity`.
- workload spoke roots can read hub VNet, private DNS, and Log Analytics outputs.
- `network-peering` reads connectivity and workload-spoke outputs to create the peering and DNS links.
- `platform-cloudflare-edge` owns Cloudflare account resources only; Azure connector VMs stay in `platform-cloudflare-connectors`.

Provider subscription context remains an explicit workspace variable or HCP dynamic credential setting. Terraform should not configure an Azure provider from a producer workspace output inside the same run.

See `WORKSPACES.md` for the deployment order and output contracts.
