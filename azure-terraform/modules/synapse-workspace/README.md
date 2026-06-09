# Synapse Workspace Module

This module manages the Synapse Workspace resource while keeping storage filesystem and administrator concerns composable.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Storage coupling | Reviewed Synapse pattern created the filesystem and workspace together. | Workspace accepts `storage_data_lake_gen2_filesystem_id`, allowing storage ownership to stay separate. |
| Security posture | Managed VNet and data exfiltration controls may be unclear. | Exposes managed virtual network and data exfiltration protection settings explicitly. |
| Admin lifecycle | AAD admin can change independently from workspace creation. | Companion module `synapse-workspace-aad-admin` owns AAD admin assignment. |

## Design Intent

This module owns:

- Synapse Workspace resource
- Filesystem attachment by ID
- SQL administrator settings
- Managed virtual network flag
- Data exfiltration protection flag
- Managed identity

Use companion modules for:

- `synapse-filesystem`
- `synapse-workspace-aad-admin`
- `private-endpoint`
- `diagnostic-settings`
- `role-assignments`

## Why This Matters

Synapse depends on storage, identity, networking, and admin configuration. Keeping those concerns composable lets platform and data teams manage their own lifecycle boundaries without forcing every Synapse workspace into one bootstrap module.

