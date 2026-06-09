# SQL Server Security Alert Policy Module

This module manages SQL Server Defender and security alert policy settings separately from server and database creation.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Security ownership | Alert policy can be buried in SQL Server creation. | Alert policy is an explicit security module. |
| Environment variance | Contacts, disabled alerts, and retention can differ. | Alert configuration is controlled through a dedicated contract. |
| Auditability | Security policy changes require clear review. | The Terraform plan shows only the security policy change. |

## Design Intent

This module owns:

- SQL Server security alert policy
- Email/account admin notification settings
- Disabled alerts
- Retention and storage settings where used

Use companion modules for:

- `sql-server`
- `storage-account`
- `action-group`
- `monitor-metric-alert`

## Why This Matters

Security posture may evolve faster than database infrastructure. Isolating this module lets governance improve without forcing unrelated SQL changes.

