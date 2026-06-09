# APIM API Module

This module manages an API published into an existing API Management service.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Decomposition | API resources were already separate from APIM service, which is good. | Preserves that separation so APIs can be released independently from the gateway service. |
| API import | Import configuration can be tightly coupled to broader APIM objects. | Keeps API definition and import settings focused on the API resource. |
| Relationships | API policies, products, backends, and named values can be forced into one module. | Those are companion modules so API lifecycle stays focused. |

## Design Intent

This module owns:

- `azurerm_api_management_api`
- API name, display name, path, revision, type, and protocols
- Optional service URL
- Optional import block
- Optional subscription key parameter names

Use companion modules for:

- `apim-api-policy`
- `apim-backend`
- `apim-product-api`
- `apim-named-value`
- `apim-policy`

## Why This Matters

API publishing changes more frequently than APIM service configuration. Keeping APIs separate supports independent release cycles and avoids turning the APIM service module into a large API delivery monolith.

