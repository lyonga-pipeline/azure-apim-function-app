# ClientSync Function App Pilot

ClientSync is the first consumer implementation of the Terraform 2.0 Function App composition pattern.

The environment roots under `environments/` model the full path from sandbox validation through `np1`, `np2`, `np3`, and `prod`. Each environment has its own HCP workspace and state boundary so promotion, review, and rollback remain explicit.

## What This Root Demonstrates

- Function App deployed through the approved composition pattern.
- Create-mode dependencies for App Service Plan, identity, Storage Account, Key Vault, and Application Insights.
- Explicit platform inputs for Log Analytics, Action Group, VNet integration subnet, private endpoint subnet, and Private DNS zones.
- Private endpoints for Function App, Key Vault, Storage blob, Storage queue, and Storage file.
- Diagnostics, RBAC, and alerting as visible pattern concerns.
- App settings managed without broad `ignore_changes`.
- Production-specific hardening in `prod`, including zone-balanced App Service capacity, ZRS Storage, longer telemetry retention, and stricter alerting thresholds.

## Apply Flow

Use the environment-specific HCP workspace for the target root:

| Environment | Root | HCP workspace |
| --- | --- | --- |
| `sandbox` | `environments/sandbox` | `lz-workload-clientsync-sandbox` |
| `np1` | `environments/np1` | `lz-workload-clientsync-np1` |
| `np2` | `environments/np2` | `lz-workload-clientsync-np2` |
| `np3` | `environments/np3` | `lz-workload-clientsync-np3` |
| `prod` | `environments/prod` | `lz-workload-clientsync-prod` |

```bash
cd clientsync/environments/np1
terraform init
terraform plan -var-file=terraform.tfvars.example
```

Use `terraform.tfvars.example` as the starting point for HCP workspace variables or a local validation variable file. Replace the placeholder subscription IDs, subnet IDs, Private DNS zone IDs, Log Analytics ID, and Action Group ID with approved platform outputs for the target environment.

The `np1` root also includes smoke-test defaults so the HCP workspace can plan with only `subscription_id` plus the Azure dynamic credential variables. Those defaults create the app resource group, managed identity, B1 App Service Plan, Storage Account, Key Vault, Application Insights, and Function App, while leaving VNet integration, private endpoints, diagnostics, and metric alerts disabled until the platform outputs are available.

For an enterprise-style deployment, override these defaults in HCP Terraform with values from the platform workspaces:

- Set `network.app_service_integration_subnet_id` to the workload spoke integration subnet ID.
- Set `private_endpoints.enabled = true`, `private_endpoints.subnet_id`, and the required `private_dns_zone_ids`.
- Set `diagnostics.enabled = true` and `diagnostics.log_analytics_workspace_id`.
- Set `alerts.enabled = true` and `alerts.action_group_id`.

If you override `location` in HCP Terraform, set it as a Terraform variable or as `TF_VAR_location`. A plain environment variable named `location` is not read as `var.location`.
