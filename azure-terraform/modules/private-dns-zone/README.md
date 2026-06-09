# Private DNS Zone Module

This module manages private DNS zones as shared networking resources.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| DNS ownership | Private DNS can be hidden inside private endpoint modules. | DNS zones are explicit shared resources. |
| Reuse | Multiple private endpoints and VNets can use the same zone. | Zone lifecycle is independent from endpoint lifecycle. |

## Design Intent

Use this module for private DNS zones. Use `private-dns-vnet-link` for VNet links and `private-endpoint` for service endpoint connectivity.

