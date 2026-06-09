# Network Interface Application Security Group Association Module

This module links network interfaces to application security groups without mixing the relationship into NIC or ASG creation.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Relationship lifecycle | NIC creation and ASG membership can be bundled together. | ASG membership is managed independently. |
| Security ownership | Security group membership may change after NIC creation. | Membership updates do not require NIC changes. |
| Composition | Different environments may use different ASGs. | Roots pass the resolved NIC and ASG IDs explicitly. |

## Design Intent

This module owns:

- Network interface to application security group association

Use companion modules for:

- `network-interface`
- `network-security-group`
- Workload modules that expose NIC IDs

## Why This Matters

Security associations are often governed separately from infrastructure creation. Keeping the association small and explicit reduces hidden network drift.

