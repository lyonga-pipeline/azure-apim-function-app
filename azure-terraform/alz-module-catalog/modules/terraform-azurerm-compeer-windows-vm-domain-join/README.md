# Windows VM Domain Join Module

This module performs Windows domain join through a VM extension as a separate guest configuration lifecycle.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Guest configuration | Domain join can be embedded in the VM base module. | Domain join is a separate extension module. |
| Credentials | Domain join credentials require different handling than VM creation. | The extension can consume secure settings independently. |
| Timing | Domain join depends on network, DNS, and domain availability. | Roots apply the extension only when dependencies are ready. |

## Design Intent

This module owns:

- Domain join VM extension
- Domain, OU, restart, and credential settings
- Protected extension settings

Use companion modules for:

- `windows-vm`
- `key-vault-secret`
- `role-assignments`
- `windows-vm-extension`

## Why This Matters

Domain join is guest state, not VM control-plane creation. Separating it keeps the VM module reusable for domain-joined and non-domain-joined workloads.

