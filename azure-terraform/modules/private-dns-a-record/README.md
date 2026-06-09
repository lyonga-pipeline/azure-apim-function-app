# Private DNS A Record Module

This companion module manages private DNS A records separately from private DNS zones and private endpoints.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Record lifecycle | A records can be hidden inside endpoint or DNS zone modules. | Records are explicit DNS data-plane objects. |
| Ownership | Some environments auto-register records while others require manual records. | Application roots can compose explicit records only when needed. |

## Design Intent

Use this module for explicitly managed private DNS A records. Prefer private endpoint DNS zone groups when that is the approved enterprise pattern.

