# Platform Tags Module

This module normalizes enterprise tags so application and platform roots can apply a consistent tag set without copying tag merge logic everywhere.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Tag consistency | Each module or app root may build tags differently. | Standard tags are generated once and reused. |
| Governance | Required ownership, cost, and classification metadata can be missed. | Environment, application, owner, repo, workspace, recovery, cost, data, and compliance tags are modeled. |
| Extensibility | Custom tags can overwrite or conflict unpredictably. | `additional_tags` are merged after normalized defaults. |

## Design Intent

This module owns:

- Standard tag normalization
- Optional operational metadata tags
- Additional tag merge behavior
- A single `tags` output for resource modules

Use companion modules for:

- All resource modules that accept `tags`

## Why This Matters

Tags are part of cost, compliance, and ownership governance. Centralizing tag construction reduces drift between teams and keeps module contracts lighter.

