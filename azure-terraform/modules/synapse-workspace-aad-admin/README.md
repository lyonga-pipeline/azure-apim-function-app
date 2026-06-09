# Synapse Workspace AAD Admin Module

This module manages Synapse workspace Microsoft Entra admin assignment separately from workspace creation.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Access lifecycle | Workspace admin can be embedded in the Synapse workspace module. | Admin assignment has its own lifecycle. |
| Ownership | Identity and access assignments can change without workspace changes. | Admin updates affect only the assignment. |
| Review | Privileged access requires clear review. | The plan clearly shows admin changes. |

## Design Intent

This module owns:

- Synapse workspace Entra admin assignment

Use companion modules for:

- `synapse-workspace`
- `role-assignments`

## Why This Matters

Privileged access is not the same lifecycle as the Synapse workspace. Keeping admin assignment separate supports least privilege and cleaner audit review.

