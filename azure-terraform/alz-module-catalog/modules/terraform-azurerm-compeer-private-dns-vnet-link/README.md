# Private DNS VNet Link Module

This companion module links private DNS zones to virtual networks.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Link lifecycle | DNS zone links can be embedded into broad network or private endpoint modules. | VNet links are explicit association resources. |
| Ownership | DNS zones and VNets may be managed by different teams. | Links can be reviewed and changed independently. |

## Design Intent

Use this module to associate private DNS zones with virtual networks. Keep DNS zones, VNets, and private endpoints in separate modules where ownership differs.

