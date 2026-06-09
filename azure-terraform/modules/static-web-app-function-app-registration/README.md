# Static Web App Function App Registration Module

This module registers a Function App with a Static Web App without coupling the two base resources together.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| App coupling | Static Web App and Function App can be built as one large pattern. | Registration is its own lifecycle relationship. |
| Ownership | Frontend and API teams may release independently. | The root composes the relationship only when both sides are ready. |
| Reuse | A Function App can be built through the standard `function-app` module. | This module only owns the registration link. |

## Design Intent

This module owns:

- Static Web App to Function App registration

Use companion modules for:

- `static-web-app`
- `function-app`
- `role-assignments`

## Why This Matters

The registration is a relationship, not a resource foundation. Isolating it keeps frontend and API lifecycle boundaries clean.

