# APIM Backend Module

This module supports the Terraform 2.0 APIM pattern by keeping backend registration separate from API definitions, products, and global APIM service configuration.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Backend lifecycle | Backends can be hidden inside API or service modules. | Backends are explicit named resources with their own contract. |
| Security settings | Credentials, proxy, and TLS options can become mixed into API policy logic. | Backend credentials, proxy, and TLS validation are modeled directly. |
| Reuse | Multiple APIs may need to target the same backend. | The backend can be created once and referenced by API policy or API modules. |

## Design Intent

This module owns:

- APIM backend registration
- Backend URL, protocol, and metadata
- Optional credentials
- Optional proxy configuration
- Optional TLS validation settings

Use companion modules for:

- `apim-service`
- `apim-api`
- `apim-api-policy`
- `apim-named-value`

## Why This Matters

Backends are part of the API control plane, but they are not the APIM instance itself. Separating them lets application teams update backend routing without forcing service-level APIM changes.

