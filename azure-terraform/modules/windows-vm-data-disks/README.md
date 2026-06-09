# Windows VM Data Disks Module

This module creates and attaches managed data disks to Windows VMs without mixing disk lifecycle into the VM base module.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| VM lifecycle | Data disks can be embedded in the VM module. | Disk creation and attachment are separate. |
| Operations | Disk sizing, count, and LUN changes often happen after VM creation. | Disk changes do not require changing the VM resource contract. |
| Reuse | Workloads need different data disk layouts. | A map-based disk input can support workload-specific layouts. |

## Design Intent

This module owns:

- Managed data disk creation
- Data disk attachment to a VM
- LUN, caching, and storage settings

Use companion modules for:

- `windows-vm`
- `windows-vm-extension`
- `diagnostic-settings`

## Why This Matters

Disk requirements evolve as applications grow. Separating disks from the VM core avoids forcing teams to fork the VM module for storage layout differences.

