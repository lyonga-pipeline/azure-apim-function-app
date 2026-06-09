# SQL Server Module

This module manages the Azure SQL logical server lifecycle while keeping databases and compliance controls separate.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Server vs database | SQL workload patterns can bundle server, databases, auditing, alerting, and app configuration together. | SQL server is separate from `sql-database` and SQL policy companion modules. |
| Security posture | TLS, public access, Entra-only auth, identity, and CMK can be inconsistent. | Exposes server-level controls explicitly, including TLS, public access, Entra auth, managed identity, and TDE key reference. |
| Compliance lifecycle | Auditing and security alert policies can evolve independently. | Uses companion modules for auditing and security alert policy lifecycles. |

## Design Intent

This module owns:

- Azure SQL logical server
- TLS and connection policy
- Public and outbound network access posture
- Entra administrator and Entra-only auth
- Managed identity
- TDE key reference

Use companion modules for:

- `sql-database`
- `sql-server-extended-auditing-policy`
- `sql-server-security-alert-policy`
- `private-endpoint`
- `diagnostic-settings`
- `role-assignments`

## Why This Matters

SQL server lifecycle is not the same as database lifecycle. Separating databases and compliance policies gives teams safer rollout paths and avoids a single SQL module becoming a workload monolith.

