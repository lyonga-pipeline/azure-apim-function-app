# APIM Policy Module

This module manages the APIM service-level policy separately from APIs, products, and API-specific policies.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Scope clarity | Global and API-level policies can be confused in a broad APIM module. | This module is only for service-level APIM policy. |
| Change control | Global policy changes can affect all APIs. | A dedicated module makes high-impact changes easier to review. |
| Promotion | Policy XML can be versioned and promoted independently. | The root module decides when the global policy changes per environment. |

## Design Intent

This module owns:

- APIM global policy
- Inline XML or XML link policy source

Use companion modules for:

- `apim-service`
- `apim-api-policy`
- `apim-api`
- `apim-product`

## Why This Matters

Global APIM policy is a shared platform control. Isolating it keeps platform-wide behavior explicit and avoids accidental coupling to individual API deployments.

