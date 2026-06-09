# Subnet Route Table Association Module

This module associates a route table with a subnet without coupling route ownership to VNet or subnet creation.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Routing lifecycle | Route table association can be embedded in the networking module. | Association is explicit. |
| Operations | Routes and subnet address spaces are governed differently. | The root composes route tables and subnets using IDs. |
| Environment variance | NP and prod may use different routing patterns. | Environment roots decide which route table applies. |

## Design Intent

This module owns:

- Subnet to route table association

Use companion modules for:

- `virtual-network`
- `route-table`

## Why This Matters

Routing decisions can affect connectivity and security. Separating the association prevents hidden changes inside a broad networking module.

