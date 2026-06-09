# Network Interface Backend Address Pool Association Module

This module attaches a NIC IP configuration to a Load Balancer backend address pool as a separate lifecycle resource.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Load balancer coupling | Backend pool membership can be hidden inside VM or Load Balancer modules. | Pool association is explicit. |
| Release cadence | VM creation and traffic membership may not happen together. | Teams can add or remove backend membership independently. |
| Reuse | Different apps may use the same load balancer pattern. | Roots pass explicit NIC IP configuration and backend pool IDs. |

## Design Intent

This module owns:

- NIC IP configuration to Load Balancer backend address pool association

Use companion modules for:

- `network-interface`
- `load-balancer`
- `windows-vm`

## Why This Matters

Traffic routing is a relationship. Managing it separately avoids changing VM or Load Balancer resources just to alter backend membership.

