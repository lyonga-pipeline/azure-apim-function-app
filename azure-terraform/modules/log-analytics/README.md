# Log Analytics Module

This module creates the Log Analytics workspace used by diagnostics, Application Insights, alerts, and platform observability patterns.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Shared resource ownership | Workspaces can be created repeatedly by workload modules. | Workspace creation is explicit and can be owned centrally. |
| Retention | Retention settings may vary without guardrails. | Retention is validated between supported bounds. |
| Cost controls | Daily quotas and reservation capacity can be omitted. | Quota and reservation capacity inputs are available. |
| Network posture | Internet ingestion/query posture should be visible. | Internet ingestion and query settings are explicit inputs. |

## Design Intent

This module owns:

- Log Analytics workspace creation
- SKU, retention, and quota settings
- Internet ingestion and query posture
- Optional reservation capacity
- Tags

Use companion modules for:

- `diagnostic-settings`
- `application-insights`
- `monitor-metric-alert`

## Why This Matters

Log Analytics is often shared across many services. This module keeps that shared observability foundation separate from application modules so teams can pin and promote workspace behavior deliberately.

