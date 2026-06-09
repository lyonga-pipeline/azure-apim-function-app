# Synapse Filesystem Module

This module creates the Data Lake Gen2 filesystem used by Synapse separately from Synapse workspace creation.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Data-plane coupling | Workspace and filesystem creation can be bundled together. | Filesystem lifecycle is separate from Synapse workspace lifecycle. |
| Ownership | Storage teams may own storage accounts and filesystems. | Synapse roots can accept filesystem IDs or compose this module explicitly. |
| Reuse | A filesystem may need independent retention or access controls. | Data-plane resource changes do not require workspace changes. |

## Design Intent

This module owns:

- Storage Data Lake Gen2 filesystem creation

Use companion modules for:

- `storage-account`
- `synapse-workspace`
- `role-assignments`

## Why This Matters

The reviewed Synapse guidance called out filesystem coupling as a concern. This module keeps the data-plane object out of the workspace lifecycle.

