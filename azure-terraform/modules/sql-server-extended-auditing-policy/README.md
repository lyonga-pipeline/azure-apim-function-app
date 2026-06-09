# SQL Server Extended Auditing Policy Module

This module manages SQL Server auditing separately from SQL Server creation and database lifecycle.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Security lifecycle | Auditing can be hidden in the SQL Server module. | Auditing is an explicit security control. |
| Storage dependency | Audit storage and retention may vary by environment. | Storage endpoint, access, and retention inputs are visible. |
| Change review | Audit changes are compliance-sensitive. | A dedicated module makes changes easier to review. |

## Design Intent

This module owns:

- SQL Server extended auditing policy
- Audit target and retention settings
- Server-level audit enablement

Use companion modules for:

- `sql-server`
- `storage-account`
- `diagnostic-settings`
- `role-assignments`

## Why This Matters

Auditing is a compliance control, not just a server property. Keeping it separate helps security and platform teams govern audit behavior without coupling it to database deployment.

