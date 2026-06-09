# App Service Certificate Module

This module manages App Service certificates as a separate lifecycle concern from web apps, function apps, and hostname bindings.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Certificate ownership | Certificates can be buried in app modules. | Certificate import is isolated and reusable. |
| Rotation | Certificate updates should not require app recreation. | Certificate lifecycle can be promoted independently. |
| Composition | A certificate may be used by multiple hostname bindings. | Binding modules can reference the certificate output. |

## Design Intent

This module owns:

- App Service certificate resource
- Certificate material or Key Vault secret reference depending on module inputs
- Certificate placement in the target resource group

Use companion modules for:

- `app-service-custom-hostname-binding`
- `app-service-certificate-binding`
- `app-service-managed-certificate`
- `key-vault-certificate`

## Why This Matters

Application hosting and certificate lifecycle have different operational owners and renewal cadences. Separating them prevents certificate changes from becoming app infrastructure changes.

