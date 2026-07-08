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
terraform plan
```

The committed `terraform.tfvars` is an autoloaded np1 pilot file. It intentionally does not contain tenant IDs, subscription IDs, subnet IDs, Private DNS zone IDs, Log Analytics IDs, or Action Group IDs. Let HCP Terraform Azure dynamic credentials provide tenant/subscription context, or set `subscription_id` and `tenant_id` as real HCP workspace variables when dynamic credentials are not available.

The `np1` root also includes pilot defaults so the HCP workspace can plan with Azure dynamic credential variables plus access to the upstream platform outputs. Those defaults create the app resource group, managed identity, Elastic Premium App Service Plan (`EP1`), Storage Account, Key Vault, Application Insights, Function App, diagnostic settings, VNet integration, and private endpoints. Metric alerts remain disabled until the platform action group is ready to be enforced for this pilot.

The fully private `np1` profile uses `allow_dedicated_app_service_plan = true` with `EP1` because classic Consumption (`Y1`) is a smoke-test fallback, not the enterprise private networking profile. If a personal/test subscription still has regional App Service Plan quota of `0`, use that only for a temporary public smoke test by setting `allow_dedicated_app_service_plan = false`, `private_endpoints.enabled = false`, `platform_outputs.enabled = false`, and `function_app.always_on = false`. For enterprise testing, request the needed App Service quota in the target subscription and region, keep `allow_dedicated_app_service_plan = true`, and use the approved Elastic Premium or Dedicated SKU.

The `np1` pilot storage account uses the enterprise defaults: `shared_access_key_enabled = false`, `public_network_access_enabled = false`, `default_action = "Deny"`, and managed identity storage binding for the Function App. This is the expected posture for OPA compliance. The `np1` AzureRM provider sets `storage_use_azuread = true` so Terraform refreshes Storage Blob/Queue data-plane properties with Entra ID instead of forbidden shared-key authentication. Hosted HCP Terraform workers may still need private connectivity, an HCP agent, or a temporary approved exception to manage Storage data-plane child resources after the account is closed to public access.

If an earlier partial apply already created Storage child resources while public access was enabled, future refresh or child-resource updates can fail from hosted runners after public network access is disabled. Prefer a private HCP agent or platform network path. If a break-glass change is needed, make it time-bound, document it as an advisory exception, and remove it before mandatory enforcement.

For an enterprise-style deployment, keep `platform_outputs.enabled = true`. The root reads declared outputs from:

- `lz-workload-online-banking-np1` for `app_service_integration_subnet_id`, `private_endpoint_subnet_id`, or the `subnet_ids` map.
- `lz-platform-connectivity-np` for App Service, Key Vault, Storage Blob, Storage Queue, and Storage File private DNS zone IDs.
- `lz-platform-management-np` for `log_analytics_workspace_id` and, later, `action_group_id`.

The app root converts those outputs into `network.app_service_integration_subnet_id`, `private_endpoints.subnet_id`, `private_endpoints.private_dns_zone_ids`, and `diagnostics.log_analytics_workspace_id`. If the producer workspaces have not applied since outputs were added, or if the HCP run cannot read those workspaces, the plan fails with a platform-output contract message. Set a sensitive `TFE_TOKEN` environment variable in the ClientSync workspace when the run environment does not already have a token that can read the producer workspace outputs.

For isolated smoke tests only, set `platform_outputs.enabled = false`, disable private endpoints, and use `diagnostics.workspace.create` to create a workload-local workspace. That posture is useful for subscription quota testing but is not the intended enterprise deployment.

If you override `location` in HCP Terraform, set it as a Terraform variable or as `TF_VAR_location`. A plain environment variable named `location` is not read as `var.location`.
