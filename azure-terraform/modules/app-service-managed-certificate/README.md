# App Service Managed Certificate Module

This module creates Azure-managed certificates for App Service hostnames while keeping certificate issuance separate from app and hostname lifecycle.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Certificate lifecycle | Managed certificates can be hidden inside app modules. | Issuance is explicit and tied to the hostname binding ID. |
| Ownership | App deployment and certificate issuance may be owned by different teams. | The root module composes the app, hostname, certificate, and binding steps. |
| Reuse | Domain workflows vary by app type. | This module can be reused for web app and function app hosting patterns. |

## Design Intent

This module owns:

- App Service managed certificate creation
- The dependency on an existing hostname binding

Use companion modules for:

- `app-service-custom-hostname-binding`
- `app-service-certificate-binding`
- `web-app`
- `function-app`

## Why This Matters

Managed certificate creation depends on hostname readiness. Keeping that as a separate module makes the dependency clear and avoids hidden ordering logic in the app module.

