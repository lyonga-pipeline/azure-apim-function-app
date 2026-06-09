# Network Security Group Module

This module manages Network Security Groups as standalone security resources.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Security lifecycle | NSGs can be embedded inside subnet or NIC modules. | NSGs are created separately from their associations. |
| Ownership | Security rules and subnet/NIC attachment may have different owners. | Association modules attach NSGs to subnets or NICs. |

## Design Intent

Use this module for NSG creation and rule definition. Use `nsg-subnet-association` or `nsg-network-interface-association` to attach it.

