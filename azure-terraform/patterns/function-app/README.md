# Function App Composition Pattern

This pattern is the first Terraform 2.0 reference workload composition. It demonstrates how a real Function App workload should be assembled from narrow base modules and companion modules without turning the base Function App module into a mixed-lifecycle mega-module.

## What The Pattern Composes

- Resource group and enterprise tags.
- User-assigned managed identity.
- App Service Plan.
- Storage Account plus optional containers, queues, and file shares.
- Key Vault plus optional secrets.
- Application Insights.
- Function App with secure defaults.
- Regional VNet integration.
- Private endpoints for Function App, Key Vault, and Storage subresources.
- Diagnostic settings.
- Optional workload-local Log Analytics workspace when a platform workspace ID is not supplied.
- RBAC assignments.
- HTTP 5xx metric alert.

## Dependency Modes

Most dependencies support:

| Mode | Meaning |
| --- | --- |
| `create` | The pattern creates the dependency through approved base/companion modules. |
| `existing` | The pattern consumes an approved dependency by explicit ID/name. |

The pattern validates that required create/existing inputs are present. It does not infer subnets, DNS zones, subscriptions, or shared observability from environment names. Diagnostics should normally point to the platform Log Analytics workspace through `diagnostics.log_analytics_workspace_id`; isolated pilots can set `diagnostics.workspace.create` to create a workload-local workspace without hardcoding subscription IDs.

Storage diagnostics are attached to service scopes such as `blobServices/default`, `queueServices/default`, and `fileServices/default` because the parent Storage Account scope does not support the `allLogs` category group used by many other Azure resources.

## App Settings Ownership

Infrastructure-owned app settings stay in Terraform. Runtime/deployment-owned settings may be passed into the pattern for sandbox validation, but broad app setting drift suppression is not used. If a setting must be ignored later, it should be documented in an exception register with owner, reason, and review cadence.

## Production Guardrails

For `prod`, the pattern requires:

- diagnostics enabled,
- private endpoints enabled,
- VNet integration subnet ID provided,
- alerting enabled,
- Log Analytics workspace ID or an explicit diagnostics workspace create block,
- Action Group ID.
