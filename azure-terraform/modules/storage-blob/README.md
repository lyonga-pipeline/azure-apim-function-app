# Storage Blob Module

This companion module manages individual storage blobs separately from the storage account and container.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Blob lifecycle | Seed files or app artifacts can be hidden inside account modules. | Blobs are explicit data-plane objects. |
| Blast radius | Updating a blob should not affect account or container lifecycle. | Blob updates stay isolated. |

## Design Intent

Use this module only when Terraform should manage a specific blob object. Avoid using it for frequently changing application data.

