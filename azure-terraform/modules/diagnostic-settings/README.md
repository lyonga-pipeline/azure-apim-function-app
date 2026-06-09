# Diagnostic Settings Module

This companion module manages Azure Monitor diagnostic settings for any supported target resource.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Observability lifecycle | Diagnostics can be embedded into every base resource module. | Diagnostics are managed separately so telemetry routing can change independently. |
| Routing | Log Analytics, Storage, Event Hub, and partner destinations can vary by environment. | Destination IDs are explicit inputs rather than hidden inside base modules. |
| Drift handling | Reviewed patterns showed diagnostic `ignore_changes` workarounds. | This module keeps diagnostic routing visible in plan output by default. |

## Design Intent

Use this module to attach logs and metrics to platform or workload resources after the base resource exists.

## Why This Matters

Telemetry routing is often owned by operations or platform observability teams. Keeping diagnostics separate avoids changing the base resource module every time logging destinations or retention expectations change.

