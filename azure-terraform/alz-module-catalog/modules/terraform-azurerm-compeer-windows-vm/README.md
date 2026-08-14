# Windows VM Module

This module is the Terraform 2.0 replacement pattern for reviewed Windows VM configurations. It owns the VM lifecycle but deliberately keeps guest configuration and post-provision actions separate.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| VM lifecycle | VM, domain join, disks, extensions, and guest configuration can become bundled together. | Core VM creation is separate from data disks, domain join, and extensions. |
| Input contract | Flat inputs can make image, availability, and identity combinations unclear. | Uses structured objects for image reference, plan, OS disk, identity, diagnostics, and capabilities. |
| Security posture | Secure boot, vTPM, encryption at host, patch mode, and diagnostics may be inconsistent. | Exposes enterprise VM controls explicitly with validation where appropriate. |
| Availability model | Zone and availability set can be mixed without clear rules. | Keeps availability set and zone as explicit inputs so pattern modules can enforce environment rules. |

## Design Intent

This module owns:

- Windows VM resource
- Base NIC attachment
- OS disk
- Image or marketplace plan selection
- Identity
- Patch and agent settings
- Secure boot, vTPM, and encryption-at-host controls
- Boot diagnostics

Use companion modules for:

- `network-interface`
- `windows-vm-data-disks`
- `windows-vm-domain-join`
- `windows-vm-extension`
- `availability-set`
- `role-assignments`
- `diagnostic-settings`
- `monitor-metric-alert`

## Why This Matters

Domain join, disk layout, guest bootstrap, and extensions change on a different cadence than VM creation. Keeping them separate reduces blast radius and lets operations teams manage Day-2 VM configuration without replacing the base VM module.

