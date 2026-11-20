# End-to-End Acceptance Gate

The repository implementation and mocked tests are not evidence that a client
credential has rotated successfully. Do not enable production assets until the
following acceptance record is completed in the approved nonproduction environment.

| Gate | Evidence required | Current status |
| --- | --- | --- |
| Terraform and runtime unit tests | Successful validation and all automated tests | Verified locally; CI added |
| Linux deployment artifact | Successful CI build, dependency hash checks and retained package digest | CI verification required |
| Azure deployment | Reviewed plan/apply, private DNS/SCM access, both app identities and indexed functions | Client deployment required |
| Scheduled rotation | Authority replacement, vault version, all consumers validated and previous credential retired | Live test required |
| Event rotation | Approved trusted-service exception, topic MI delivery, stale/duplicate event suppression and recovery | Live test required; scheduler-only is default |
| Planned manual rotation | Approved operator token, expiring request authorization and complete execution evidence | Live test required |
| Emergency rotation | Clean worker identity, incident approval, validated replacement and immediate post-validation retirement | Incident exercise required |
| Safety and recovery | Concurrent workers, lost lease, interrupted creation/publication/retirement, expired approval and DLQ replay | Local regression coverage plus live fault injection required |
| Monitoring | Healthy heartbeat; deliberately triggered backlog, failure, overdue and dead-letter alerts reach Operations | Live alert-routing test required |
| Governance | Approved inherited/explicit policy assignments, IAM consent, asset inventory, consumer contracts and recovery procedure | Client approvals required |

Supported authority adapters are Storage dual keys and Entra application passwords.
Native key policies and integrated-CA certificate renewal are separate modules.
Certificate endpoint deployment, database/third-party/PAM adapters and custom
consumer refresh/validation implementations are not generic completed integrations.
They require service-specific engineering and acceptance before onboarding.

For every test asset, retain its cycle ID, source credential IDs, vault version,
consumer acknowledgments, fresh-authentication results, old-credential retirement
result and approved change/incident reference. Never retain credential values.
