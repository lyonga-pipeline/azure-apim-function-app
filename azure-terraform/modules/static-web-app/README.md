# Static Web App Module

This module creates Azure Static Web Apps with secure defaults and keeps custom domains, function registrations, and diagnostics as companion lifecycles.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Hosting pattern | Static Web Apps can be treated as another web app variant. | Static Web App has a focused module with its own contract. |
| Secure defaults | Public access, preview environments, and repo integration can vary. | Public access is disabled by default and preview/config changes are explicit. |
| Secrets | Repository tokens and app settings may be exposed casually. | Sensitive values are marked sensitive. |
| Identity | Identity support is modeled without requiring custom stitching. | Optional managed identity is included. |

## Design Intent

This module owns:

- Static Web App resource
- SKU tier and size
- Optional repository integration
- Basic auth settings
- Managed identity
- App settings
- Tags

Use companion modules for:

- `static-web-app-custom-domain`
- `static-web-app-function-app-registration`
- `diagnostic-settings`
- `role-assignments`

## Why This Matters

Static Web Apps have a different lifecycle than App Service apps. A dedicated module avoids forcing application teams through a web app pattern that does not fit static hosting.

