# NSG Network Interface Association Module

This module associates a Network Security Group with a network interface independently from NIC and NSG creation.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Network security lifecycle | NSG association can be buried in NIC modules. | Association is explicit and independently managed. |
| Ownership | Security teams may govern NSGs while app teams own VMs. | The root composes the relationship at the correct boundary. |
| Drift control | Association changes should not alter NIC configuration. | Only the association resource changes. |

## Design Intent

This module owns:

- Network interface to NSG association

Use companion modules for:

- `network-interface`
- `network-security-group`
- `windows-vm`

## Why This Matters

NSG association is a network control-plane relationship. Separating it keeps infrastructure creation and security attachment from stepping on each other.

