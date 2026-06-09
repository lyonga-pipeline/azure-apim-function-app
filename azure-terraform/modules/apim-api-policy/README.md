# APIM API Policy Module

This module supports the Terraform 2.0 APIM pattern by keeping API-level policy ownership separate from the APIM service and API definition lifecycles.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Lifecycle ownership | APIM service, APIs, products, and policies can be bundled together. | API policy changes are isolated to the API policy lifecycle. |
| Release cadence | A policy update can force broad APIM module plans. | Policy XML can be promoted independently from service infrastructure. |
| Composition | API teams may need different policy release timing than platform teams. | Application roots compose this module after the target API exists. |

## Design Intent

This module owns:

- API-level APIM policy attachment
- Inline XML or XML link policy source
- The relationship between one API and its policy

Use companion modules for:

- `apim-service`
- `apim-api`
- `apim-backend`
- `apim-product`
- `apim-product-api`

## Why This Matters

APIM policies are application-facing configuration and often change more frequently than the APIM instance. Keeping policies separate reduces blast radius and supports safer promotion workflows.

