# Web App Slot Module

This companion module manages Web App deployment slots separately from the base Web App.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Slot lifecycle | Slots can be mixed into the web app module. | Slots can be created and changed without changing the base app lifecycle. |
| Release flexibility | Slot usage varies by workload. | Workload roots compose slots only where needed. |

## Design Intent

Use this module for blue/green, staging, or validation slot patterns. Keep custom domains, certificates, diagnostics, and VNet integration separate when their lifecycle differs.

