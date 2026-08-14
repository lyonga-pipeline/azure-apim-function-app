# Action Group Module

This module manages Azure Monitor Action Groups as a focused operational companion module.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Scope | Reviewed module was already narrow and reusable. | Keeps action group lifecycle focused and independent from alerts. |
| Receiver contract | Receiver support can be too narrow or examples can contain sensitive-looking values. | Uses a structured `receivers` object and keeps receiver values as explicit inputs. |
| Composition | Alerts and action groups can be bundled into every workload module. | Action groups are reusable across many alert modules and workloads. |

## Design Intent

This module owns:

- Monitor Action Group resource
- Action group enabled state
- Email and automation runbook receivers supported by the module contract
- Standard outputs for alert composition

Use companion modules for:

- `monitor-metric-alert`
- service-specific diagnostic and alert patterns

## Why This Matters

Action groups are shared operational targets. Keeping them separate lets alert thresholds and monitored resources change without recreating notification channels.

