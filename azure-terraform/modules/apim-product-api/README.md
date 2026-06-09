# APIM Product API Link Module

This module links APIM APIs to APIM products without mixing that relationship into the APIM service, product, or API modules.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Relationship ownership | API-to-product links can be embedded in either product or API modules. | The link is a small explicit lifecycle resource. |
| Scale | Product membership may vary by environment. | `for_each` supports environment-specific product/API relationships. |
| Blast radius | A membership change should not recreate products or APIs. | Only the association changes. |

## Design Intent

This module owns:

- APIM product-to-API associations
- Multiple links through a map input

Use companion modules for:

- `apim-service`
- `apim-api`
- `apim-product`

## Why This Matters

Associations are lifecycle boundaries too. Keeping product membership separate lets API exposure decisions move through governance without forcing unrelated APIM infrastructure changes.

