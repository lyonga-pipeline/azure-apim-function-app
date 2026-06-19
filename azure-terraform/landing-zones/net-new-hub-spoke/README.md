# Net-New Hub/Spoke Landing Zone

This pattern is the first implementation path for Compeer's new Azure IaC foundation. It uses HCP Terraform workspaces, the Terraform 2.0 module catalog, policy-as-code, and explicit platform outputs to deploy a hub/spoke landing zone without inheriting legacy drift.

## Workspace Order

| Order | Root | Purpose | Produces |
| --- | --- | --- | --- |
| 1 | `global-governance` | Management group and subscription placement scaffold | Management group IDs, subscription placement outputs |
| 2 | `platform-management` | Shared observability foundation | Log Analytics workspace ID, action group ID |
| 3 | `platform-connectivity` | Hub/spoke network, subnets, NSGs, route tables, Private DNS | VNet IDs, subnet ID maps, private DNS zone IDs |
| 4 | `platform-identity` | Platform identity and vault foundation | Identity principal IDs, Key Vault URI/ID |
| 5 | `workload-spoke` | Pilot workload landing zone composition | App resource outputs and evidence for the pattern |

## Promotion Approach

Start with non-production. Prove the pattern with one pilot workload, then promote by environment only after policy, drift, diagnostics, access, and rollback expectations are validated.

## Shared Output Contract

Platform workspaces publish explicit outputs for workload workspaces to consume. Workload modules receive exact IDs rather than inferring placement internally.

Required shared outputs include:

- `log_analytics_workspace_id`
- `action_group_id`
- `subnet_ids`, keyed by purpose such as `app_integration`, `private_endpoints`, `apim`
- `private_dns_zone_ids`, keyed by service such as `app_service`, `key_vault`, `storage_blob`
- platform identity or Key Vault IDs where workloads are approved to consume them

## Enforcement Approach

OPA and Azure Policy begin in advisory/reporting mode for early validation, then move to blocking enforcement for the net-new landing-zone project once the pilot has passed. Existing projects remain outside the blocking policy set until they are remediated.

