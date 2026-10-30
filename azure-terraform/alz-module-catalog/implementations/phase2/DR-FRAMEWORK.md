# Disaster Recovery Framework

**PHASE2 NEW: v5 11.1.** This is the decision/evidence framework for future regional implementation, not a statement that regional DR is deployed.

## Required Workload Record

| Field | Required approval/evidence |
| --- | --- |
| Workload, owner, tier | Business service owner and technical recovery owner; asset and dependency inventory |
| Criticality | Business-impact assessment; outage tolerance, integrity and confidentiality needs |
| RTO | Maximum approved service recovery time; include detection, decision and dependency startup |
| RPO | Maximum approved data loss; prove backup/replication freshness and transaction consistency |
| Recovery pattern | Restore/redeploy, pilot light, warm standby or active/active; cost and dependency justification |
| Recovery location | Approved region/data residency, capacity, service/SKU and key/identity availability |
| Data recovery | Backup/replication scope, retention, immutability, restore credentials and validation |
| Network/identity | DNS cutover, firewall/routes, AD/Entra dependencies, certificates, secrets and access approvals |
| Execution | Named incident authority, ordered runbook, access process, rollback/failback and communications |
| Test | Approved cadence, isolated restore/failover evidence, measured RTO/RPO, defects and remediation owners |

## Tier Decision Template

Business/Security approve tier targets; do not infer them from names such as gold/silver/bronze. Record numeric RTO/RPO per application and select the lowest-complexity design that meets them. Identity, DNS, connectivity, keys and monitoring must recover before dependent applications. Two availability zones and backup alone do not establish regional DR.

## Exercise and Acceptance

1. Restore representative data in an isolated subscription/network using approved recovery identities.
2. Measure from incident declaration to functional application recovery, including dependency sequencing.
3. Verify consistency, authorization, secret/key access, DNS, routes, monitoring and SOC evidence.
4. Exercise rollback/failback and backup integrity without overwriting production.
5. Compare actual RTO/RPO with approved targets, assign gaps and obtain business sign-off.

Retain runbook version, Terraform/pattern versions, recovery point, timestamps, operator approvals, test results and unresolved risks in the approved evidence store. Secondary-region resources and automatic cutover remain Phase 3 until this record is approved.
