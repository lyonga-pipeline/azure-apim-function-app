# Role Definition Module

This module creates custom Azure role definitions separately from role assignments and resource modules.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Access design | Custom permissions can be mixed with assignment logic. | Role definition and role assignment are separate lifecycles. |
| Governance | Permissions need careful review before assignment. | Permissions are modeled as explicit action and data action sets. |
| Reuse | One custom role may be assigned to many principals. | The role definition can be created once and consumed by `role-assignments`. |

## Design Intent

This module owns:

- Custom role definition
- Permission actions and data actions
- Assignable scopes
- Optional stable role definition ID

Use companion modules for:

- `role-assignments`
- Resource modules that expose scope IDs

## Why This Matters

Role definitions define what access means. Role assignments define who receives it. Separating the two supports least privilege review and cleaner access governance.

