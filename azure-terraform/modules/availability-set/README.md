# Availability Set Module

This module provides a focused availability set resource for VM workloads without mixing it with VM creation, SQL configuration, domain join, or backup concerns.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Workload composition | Availability set, VM, disks, and guest configuration can be bundled into one pattern. | The availability set is a standalone resource that VM modules can reference. |
| Lifecycle | Availability set selection is an infrastructure placement decision. | Guest configuration and app setup remain outside this module. |
| Reuse | Different VM workloads may share the same placement pattern. | The module exposes a clean ID for VM composition. |

## Design Intent

This module owns:

- Availability set creation
- Fault domain and update domain settings
- Optional proximity placement group reference
- Tags

Use companion modules for:

- `windows-vm`
- `windows-vm-data-disks`
- `windows-vm-domain-join`
- `windows-vm-extension`

## Why This Matters

VM placement, VM operating system configuration, and application setup change on different cadences. Keeping the availability set separate prevents a workload pattern from becoming a hard-to-reuse VM mega-module.

