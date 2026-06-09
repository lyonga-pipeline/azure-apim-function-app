# Virtual Network Module

This module manages virtual networks and subnets with stable map-based subnet keys.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Subnet modeling | Subnets are often modeled as ordered lists or embedded inside broad landing-zone modules. | Uses `map(object(...))` for subnets so each subnet has a stable key and less plan churn. |
| Ownership | Network, subnet attachments, NSGs, routes, and private DNS can be bundled together. | VNet and subnets are kept separate from NSG, route table, NAT, and DNS associations. |
| Outputs | App modules need service-specific subnet IDs. | Outputs a `subnet_ids` map keyed by subnet name. |

## Design Intent

This module owns:

- Virtual network resource
- Subnet resources
- Address spaces and DNS server configuration
- Service endpoints and delegations per subnet

Use companion modules for:

- `network-security-group`
- `nsg-subnet-association`
- `route-table`
- `subnet-route-table-association`
- `nat-gateway-subnet-association`
- `vnet-peering`
- `private-dns-vnet-link`

## Why This Matters

Virtual network lifecycle and attachment lifecycle are often owned by different teams. Keeping associations separate prevents broad network modules from becoming the place where every application-specific decision is hidden.

