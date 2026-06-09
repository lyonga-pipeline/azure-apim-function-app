# App Service Custom Hostname Binding Module

This companion module manages custom hostname bindings separately from App Service resources.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| DNS lifecycle | Hostname binding can be embedded in app modules. | DNS and hostname validation can happen independently from app creation. |
| Ownership | DNS ownership may sit outside the app team. | App roots compose hostname binding only after DNS prerequisites are met. |

## Design Intent

Use this module for custom hostname binding after the Web App or Function App exists. Pair with certificate modules when TLS binding is required.

