# Load Balancer Module

This module provides a reusable Azure Load Balancer pattern with frontend configuration, backend pools, probes, and rules modeled as maps.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Input model | Listener and rule-style resources can become repeated blocks or environment-specific variants. | Frontends, backend pools, probes, and rules use stable map-based contracts. |
| Lifecycle | Public IPs, NIC associations, and subnet design are separate concerns. | This module owns the load balancer core and lets roots compose dependencies. |
| Reuse | Internal and external load balancers need different inputs. | Frontend configuration supports subnet or public IP references. |

## Design Intent

This module owns:

- Load Balancer resource
- Frontend IP configurations
- Backend address pools
- Health probes
- Load balancing rules

Use companion modules for:

- `public-ip`
- `network-interface-backend-address-pool-association`
- `virtual-network`
- `network-security-group`

## Why This Matters

Load balancing is shared infrastructure for several workload types. Keeping dependencies explicit avoids hidden coupling to network creation, public IP creation, or NIC lifecycle.

