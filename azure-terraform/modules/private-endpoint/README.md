# Private Endpoint Module

This module is the Terraform 2.0 replacement pattern for reviewed Private Endpoint configurations. It keeps private connectivity focused and composable while avoiding hidden DNS or network ownership assumptions.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Connection contract | Resource ID, alias, manual approval, and DNS can be passed in complex or conflicting ways. | Uses a typed `private_service_connection` object with validation for common conflict scenarios. |
| DNS ownership | DNS zone group can become tightly coupled to every endpoint. | DNS zone group is optional so central DNS ownership can be respected. |
| Drift handling | Reviewed module used `ignore_changes` for fields including tags and connection fields. | Contract is explicit and avoids hiding drift by default. |
| IP configuration | Advanced IP configuration exists but should not complicate common usage. | Supports optional `ip_configurations` while keeping the common case simple. |

## Design Intent

This module owns:

- Private endpoint resource
- Private service connection
- Optional private DNS zone group
- Optional IP configurations
- Custom network interface name

Use companion modules for:

- `private-dns-zone`
- `private-dns-vnet-link`
- `private-dns-a-record`
- `role-assignments`
- `diagnostic-settings` where supported by the target service

## Why This Matters

Private endpoint ownership often sits between application, network, DNS, and platform teams. This module keeps the endpoint composable and makes DNS attachment explicit rather than assuming every organization manages private DNS the same way.

