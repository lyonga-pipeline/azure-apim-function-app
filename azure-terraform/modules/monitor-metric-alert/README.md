# Monitor Metric Alert Module

This companion module manages Azure Monitor metric alerts separately from the resources being monitored.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Alert lifecycle | Alerts can be embedded into workload resource modules. | Alerts are separate so thresholds and action groups can change independently. |
| Criteria support | Simple alert modules may only support basic criteria. | Supports static criteria, dynamic criteria, web test availability criteria, and multiple actions. |
| Operations ownership | App teams and operations teams may own alert behavior differently. | Alert rules can be composed around any resource scope. |

## Design Intent

Use this module to create reusable operational alerts for workloads and platform resources. Pair it with `action-group` for notification routing.

## Why This Matters

Alert thresholds and action routing often change after the infrastructure resource is stable. Keeping alerts separate prevents operational tuning from changing the base resource lifecycle.

