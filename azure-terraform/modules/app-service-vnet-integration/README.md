# App Service VNet Integration Module

This companion module manages regional VNet integration separately from Web App and Function App resources.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Network lifecycle | VNet integration can be embedded into app modules. | Network attachment is managed as a separate lifecycle. |
| Ownership | App teams and network teams may own different parts of connectivity. | Subnet IDs are resolved by the application root or pattern module and passed explicitly. |

## Design Intent

Use this module when a Web App or Function App needs outbound VNet integration. Use `private-endpoint` separately for inbound private connectivity.

