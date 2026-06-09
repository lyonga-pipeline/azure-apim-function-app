# Application Insights Module

This module provides the observability component that web apps, function apps, APIs, and background workloads can consume without embedding monitoring creation into each workload module.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Observability lifecycle | App Insights can be embedded in every app module. | App Insights is created independently and passed to workloads. |
| Workspace model | Workspace-based App Insights may be inconsistent. | `workspace_id` is an explicit input for centralized Log Analytics integration. |
| Security defaults | Local authentication and retention choices can vary by team. | Local authentication is disabled by default and retention is validated. |
| Cost controls | Data caps and sampling may be omitted. | Daily cap and sampling inputs are available. |

## Design Intent

This module owns:

- Application Insights resource
- Workspace association
- Retention and sampling settings
- Internet ingestion/query settings
- Standard outputs for connection strings and instrumentation keys

Use companion modules for:

- `log-analytics`
- `diagnostic-settings`
- `monitor-metric-alert`
- `function-app`
- `web-app`

## Why This Matters

Observability is a platform standard, but each application may need different retention, sampling, and cost settings. This module standardizes the foundation while keeping workload modules focused.

