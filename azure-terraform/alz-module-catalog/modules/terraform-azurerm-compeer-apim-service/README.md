# APIM Service Module

This module manages the API Management service lifecycle and preserves the APIM family decomposition observed in the reviewed configuration.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Module family | APIM service, APIs, and products were already separated, which is a good pattern. | Keeps APIM service separate from APIs, policies, products, named values, and backends. |
| Service lifecycle | Base service can become overloaded with API publishing concerns. | Focuses on the APIM service resource, networking mode, identity, security, protocols, sign-in, and sign-up settings. |
| Input contract | Large service interface can be hard to consume without examples. | Uses typed singleton objects for optional configuration areas. |
| Diagnostics | Reviewed pattern showed diagnostic settings with drift exceptions. | Diagnostics are handled by the generic `diagnostic-settings` companion module. |

## Design Intent

This module owns:

- APIM service resource
- Publisher details
- SKU
- Public network access
- Virtual network type and configuration
- Managed identity
- Service-level security/protocol settings
- Sign-in and sign-up settings

Use companion modules for:

- `apim-api`
- `apim-api-policy`
- `apim-product`
- `apim-product-api`
- `apim-backend`
- `apim-named-value`
- `apim-policy`
- `apim-custom-domain`
- `private-endpoint`
- `diagnostic-settings`
- `role-assignments`

## Why This Matters

The reviewed APIM family was heading in the right direction by separating APIM service, API, and product concerns. This module keeps that direction and makes the APIM service the stable platform boundary while API publishing remains independently deployable.

