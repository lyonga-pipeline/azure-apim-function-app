# Static Web App Custom Domain Module

This module manages custom domains for Azure Static Web Apps separately from the Static Web App resource.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Domain lifecycle | Custom domains can be embedded in the Static Web App module. | Domain binding is a separate lifecycle. |
| DNS dependency | Domain validation may depend on external DNS timing. | The root controls when to apply the domain module. |
| Promotion | Domains may differ between environments. | Environment-specific domain bindings are explicit. |

## Design Intent

This module owns:

- Static Web App custom domain binding
- Domain validation settings exposed by the resource

Use companion modules for:

- `static-web-app`
- `private-dns-a-record` or external DNS workflows where applicable

## Why This Matters

Domain validation and app creation do not always move together. Separating this resource makes DNS dependencies easier to sequence.

