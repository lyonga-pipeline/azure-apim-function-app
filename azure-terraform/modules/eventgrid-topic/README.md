# Event Grid Topic Module

This module manages an Event Grid custom topic as a focused publisher resource.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Publisher vs subscriber | Topic and subscription concerns can be bundled together. | Topic lifecycle is separate from event subscriptions. |
| Security posture | Public access, local auth, identity, and IP rules can be inconsistent. | Exposes those controls explicitly in the topic module. |
| Reuse | Multiple subscribers can attach to the same topic. | Subscriptions are managed with `eventgrid-subscription`. |

## Design Intent

This module owns:

- Event Grid custom topic
- Input schema
- Public network access
- Local auth
- Managed identity
- Inbound IP rules

Use companion modules for:

- `eventgrid-subscription`
- `private-endpoint`
- `diagnostic-settings`
- `role-assignments`

## Why This Matters

Publishers and subscribers are often owned by different teams. Keeping topics and subscriptions separate lets subscribers evolve independently without changing the publisher resource.

