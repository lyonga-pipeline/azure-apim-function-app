# APIM Product Module

This module manages an APIM product as a focused child resource of API Management.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Scope | Product module was already small and focused. | Keeps product lifecycle separate from service, API, policy, and product/API association lifecycle. |
| Reuse | Product concerns can be mixed into API publication modules. | Products can be managed by API platform teams independently. |
| Relationships | Product-to-API attachment and product policy can be separate release actions. | Uses companion modules such as `apim-product-api` and policy modules. |

## Design Intent

This module owns:

- APIM product resource
- Product display name, approval, subscription settings, published state, terms, and description

Use companion modules for:

- `apim-product-api`
- `apim-policy`
- `apim-api-policy`

## Why This Matters

The module is intentionally thin. That is a strength when product lifecycle is separate from API lifecycle and APIM service lifecycle.

