# App Service Certificate Binding Module

This companion module manages App Service certificate bindings separately from the app resource.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| TLS lifecycle | Certificate binding can be embedded into app modules. | Certificate attachment can change without changing app lifecycle. |
| Ownership | Certificate material and app runtime may have different owners. | Certificates and bindings are composed explicitly. |

## Design Intent

Use this module after hostname binding and certificate resources exist. Keep certificate creation, Key Vault certificate storage, and app runtime configuration separate.

