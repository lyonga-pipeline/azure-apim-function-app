# Storage Management Policy Module

This module manages storage lifecycle management rules separately from the storage account and child data objects.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Data lifecycle | Retention and tiering rules can be embedded in the storage account module. | Management policy has its own lifecycle. |
| Application variance | Blob cleanup and archive rules vary by workload. | Rules are passed explicitly by each app or pattern root. |
| Safety | Lifecycle rules can delete or move data. | A dedicated module makes review and promotion safer. |

## Design Intent

This module owns:

- Storage account management policy
- Lifecycle rules for tiering, deletion, and retention

Use companion modules for:

- `storage-account`
- `storage-container`
- `storage-blob`

## Why This Matters

Storage lifecycle policy affects data retention and cost. It should be visible as a separate decision, not hidden inside storage account creation.

