# Web App Module

This module is the Terraform 2.0 replacement pattern for reviewed Web App configurations. It keeps the Web App complete enough for common app scenarios while avoiding a single all-in-one app platform module.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Operating system support | Separate or Windows-focused patterns often require variants. | Supports Windows and Linux through one `os_type` contract. |
| Input contract | List-wrapped singleton dynamic blocks and raw lookups make consumption harder. | Uses typed object inputs and null for optional singleton blocks. |
| Secure defaults | Consumers must remember HTTPS, TLS, public access, and publishing settings. | Defaults to private public-network posture, HTTPS-only, disabled FTP/WebDeploy basic auth, HTTP/2, and TLS/SCM TLS minimums. |
| Authentication | Older auth settings can lag provider capability. | Supports `auth_settings_v2` for modern App Service authentication. |
| Lifecycle separation | Slots, VNet integration, domains, cert bindings, diagnostics, and private endpoints can become mixed in. | Those concerns are companion modules with independent lifecycle. |

## Design Intent

This module owns:

- Windows or Linux Web App resource
- Service plan attachment
- Managed identity
- App settings and connection strings
- Site configuration
- Runtime stack
- Sticky settings
- Built-in App Service authentication v2
- Secure resource-level defaults

Use companion modules for:

- `app-service-plan`
- `app-service-vnet-integration`
- `web-app-slot`
- `app-service-custom-hostname-binding`
- `app-service-certificate-binding`
- `private-endpoint`
- `diagnostic-settings`
- `monitor-metric-alert`
- `role-assignments`

## Why This Matters

The module is reusable without becoming a mega-module. It gives app teams a secure and complete Web App resource while allowing networking, DNS, TLS, slots, access, and observability to move on their own release cycles.

