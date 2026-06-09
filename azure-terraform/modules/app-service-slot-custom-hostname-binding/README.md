# App Service Slot Custom Hostname Binding Module

This module manages custom hostname bindings for deployment slots separately from the parent app and slot resources.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Slot concerns | Slot hostnames can be mixed into web app or function app modules. | Slot hostname binding has its own lifecycle. |
| Promotion | Slots may need different hostnames than production. | Each slot binding is explicit and environment-controlled. |
| Blast radius | Hostname changes should not change the app or slot resource. | Only the binding is updated. |

## Design Intent

This module owns:

- Custom hostname binding for an App Service slot
- Hostname-to-slot relationship

Use companion modules for:

- `web-app-slot`
- `function-app-slot`
- `app-service-managed-certificate`
- `app-service-certificate-binding`

## Why This Matters

Slots are part of release workflow. Their custom domains should be composable so teams can validate traffic routing without changing the base application resource.

