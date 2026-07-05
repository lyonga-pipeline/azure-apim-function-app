# Legacy App Function App Demo

`legacy-app` is a training workload that intentionally contrasts with the `clientsync` composition pilot.

ClientSync separates contracts and lifecycles across resource group, identity, App Service Plan, Storage, Key Vault, Application Insights, Function App, diagnostics, RBAC, private endpoints, and alerts. This legacy demo does the opposite: one large module creates the Function App and nearly every dependency directly.

## Purpose

Use this workload to show why broad all-in-one modules are difficult to govern:

- one module contract mixes naming, app settings, tags, network posture, identity, secrets posture, Storage, Key Vault, App Insights, and Function App behavior,
- a small tag or network change forces the whole legacy module through one plan boundary,
- diagnostics and private networking are not separate lifecycle concerns,
- policy findings are harder to remediate surgically because the module owns everything at once.

## Intentional Policy Findings

The `np1` configuration is intentionally not enterprise compliant. It is designed to produce HCP OPA advisory warnings for training.

Expected findings include:

- missing required enterprise tags: `recovery`, `cost_center`, `data_classification`, and `compliance_boundary`,
- public Storage Account network access,
- Storage Account shared keys enabled,
- public nested blob item setting enabled,
- public Key Vault network access,
- Key Vault RBAC authorization disabled,
- Key Vault purge protection disabled,
- Key Vault soft delete retention below 90 days,
- public Function App network access,
- HTTPS-only disabled,
- weak Function App and SCM TLS settings,
- FTP/WebDeploy basic publishing authentication enabled,
- missing diagnostic settings for required resource types.

The App Service Plan uses Consumption `Y1` so the demo can plan/apply in subscriptions with low dedicated App Service quota.

## Root

| Environment | Root | HCP workspace |
| --- | --- | --- |
| `np1` | `environments/np1` | `lz-workload-legacy-app-np1` |

Run locally for validation only:

```bash
cd consumer-repos/online-banking/legacy-app/environments/np1
terraform init
terraform validate
```

Run in HCP Terraform to show advisory policy behavior alongside the compliant ClientSync scenario.

## Teaching Contrast

Use `legacy-app` and `clientsync` together:

- `legacy-app`: intentionally broad, tightly coupled, policy-noisy module.
- `clientsync`: separated composition pattern with clearer dependency contracts and independently governed lifecycles.
