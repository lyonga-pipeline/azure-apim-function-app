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

The committed `terraform.tfvars` is an autoloaded np1 smoke-test file. It intentionally does not contain tenant IDs, subscription IDs, subnet IDs, Private DNS zone IDs, Log Analytics IDs, or Action Group IDs. Let HCP Terraform Azure dynamic credentials provide tenant/subscription context, or set `subscription_id` and `tenant_id` as real HCP workspace variables when dynamic credentials are not available.

The `np1` root also includes pilot defaults so the HCP workspace can plan with only `subscription_id` plus the Azure dynamic credential variables. Those defaults create the app resource group, managed identity, Consumption App Service Plan (`Y1`), Storage Account, Key Vault, Application Insights, Function App, a workload-local Log Analytics workspace, and diagnostic settings. VNet integration, private endpoints, and metric alerts remain disabled until the platform outputs are available.

The `np1` smoke-test plan intentionally forces create-mode deployments to a Consumption plan (`Y1`) and `always_on = false` because personal/test Azure subscriptions can have a regional App Service Plan quota of `0` for dedicated SKUs such as `B1`. This guard also prevents stale HCP object-variable overrides from accidentally selecting a dedicated SKU. For enterprise testing, request the needed App Service quota in the target subscription and region, set `allow_dedicated_app_service_plan = true`, then override `app_service_plan.create.sku_name` with the approved Dedicated or Premium SKU and set `function_app.always_on = true` where supported.

The `np1` pilot storage account uses the enterprise defaults: `shared_access_key_enabled = false`, `public_network_access_enabled = false`, `default_action = "Deny"`, and managed identity storage binding for the Function App. This is the expected posture for OPA compliance. The `np1` AzureRM provider sets `storage_use_azuread = true` so Terraform refreshes Storage Blob/Queue data-plane properties with Entra ID instead of forbidden shared-key authentication. Hosted HCP Terraform workers may still need private connectivity, an HCP agent, or a temporary approved exception to manage Storage data-plane child resources after the account is closed to public access.

If an earlier partial apply already created Storage child resources while public access was enabled, future refresh or child-resource updates can fail from hosted runners after public network access is disabled. Prefer a private HCP agent or platform network path. If a break-glass change is needed, make it time-bound, document it as an advisory exception, and remove it before mandatory enforcement.

For an enterprise-style deployment, override these defaults in HCP Terraform with values from the platform workspaces:

- Set `network.app_service_integration_subnet_id` to the workload spoke integration subnet ID.
- Set `private_endpoints.enabled = true`, `private_endpoints.subnet_id`, and the required `private_dns_zone_ids`.
- Set `diagnostics.enabled = true` and `diagnostics.log_analytics_workspace_id` to the platform workspace. For isolated pilots, use `diagnostics.workspace.create` to create a workload-local workspace.
- Set `alerts.enabled = true` and `alerts.action_group_id`.

If you override `location` in HCP Terraform, set it as a Terraform variable or as `TF_VAR_location`. A plain environment variable named `location` is not read as `var.location`.
