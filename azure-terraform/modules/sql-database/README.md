# SQL Database Module

This module creates Azure SQL databases independently from the SQL Server control plane and server-level security configuration.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Lifecycle boundary | SQL server and databases can be bundled into one module. | Database lifecycle is separate from server lifecycle. |
| Application ownership | Databases may be provisioned per application or per release. | Roots can create databases without changing the server. |
| Configuration | SKU, collation, backup, and zone settings vary by workload. | Database settings are controlled through a focused database contract. |

## Design Intent

This module owns:

- Azure SQL database resource
- Database SKU and sizing settings
- Backup, retention, collation, and zone options where supported
- Tags and outputs

Use companion modules for:

- `sql-server`
- `sql-server-extended-auditing-policy`
- `sql-server-security-alert-policy`
- `private-endpoint`
- `diagnostic-settings`

## Why This Matters

SQL Server is a shared control-plane resource, while databases often follow application lifecycle. Splitting them prevents database changes from forcing server-level plans.

