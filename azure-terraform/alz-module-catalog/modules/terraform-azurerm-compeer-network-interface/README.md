# Network Interface Module

This module manages network interfaces separately from virtual machines and load balancer associations.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| NIC lifecycle | NICs can be hidden inside VM modules. | NICs can be managed independently and passed to VM modules. |
| Attachments | NSGs, ASGs, and backend pools often have separate ownership. | Association modules own those attachments. |

## Design Intent

Use this module for base NIC creation. Use companion modules for NSG association, ASG association, backend pool association, and VM attachment.

