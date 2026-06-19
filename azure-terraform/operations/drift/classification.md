# Drift Classification

Drift is any difference between Terraform state/configuration and the real Azure resource posture. The new landing-zone path treats drift as an operational signal, not just a Terraform error.

## Drift Categories

| Category | Description | Default action |
| --- | --- | --- |
| Authorized emergency change | Break-glass production change made outside Terraform | Record exception, create remediation PR, close after state/config is corrected |
| Unauthorized manual change | Portal/CLI/API change with no approved record | Escalate to owner, revert or codify, review access controls |
| Platform external mutation | Change made by Azure Policy, Defender, backup, monitoring, or platform automation | Decide whether to codify, ignore with evidence, or move ownership |
| Provider/API noise | Read-only or computed value churn that does not represent real risk | Document, suppress only when safe, or wait for provider fix |
| Import/migration gap | Existing resource not fully represented after onboarding | Add import/remediation backlog item |
| Security or compliance drift | Public exposure, missing diagnostics, weakened TLS, missing tags, or access change | Treat as high priority and remediate within SLA |

## Automation Rules

Drift classification should be driven by rule metadata before a human triage meeting. Use [drift-rules.yml](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/azure-terraform/operations/drift/drift-rules.yml:1) as the first-pass rule source.

| Rule | Common match | Severity | SLA | Action |
| --- | --- | --- | --- | --- |
| `security_policy_drift` | Public access, TLS, network ACL, storage public access, firewall posture | Critical | 5 days | Remediate or create approved exception |
| `manual_change_drift` | Default match when no safer rule applies | High | 7 days | Reconcile through Terraform or document break-glass exception |
| `tag_drift` | Required tag variance | Medium | 10 days | Reconcile required tags through Terraform |
| `provider_normalization` | `id`, `etag`, `last_modified`, computed-only churn | Low | 30 days | Document and suppress only with justification |

## Severity

| Severity | Trigger | Target response |
| --- | --- | --- |
| P1 | Internet exposure, privilege escalation, data protection disabled, production outage risk | Same business day |
| P2 | Compliance control weakened, diagnostics disabled, network route/NSG changed | 2 business days |
| P3 | Tagging, naming, cost allocation, non-prod drift with limited risk | 5 business days |
| P4 | Provider noise, documentation-only gap, planned future cleanup | Next backlog cycle |

Automated classification maps to work-item priority as follows:

| Automated severity | Work item priority | Default SLA |
| --- | --- | --- |
| Critical | 1 | 5 days |
| High | 2 | 7 days |
| Medium | 3 | 10 days |
| Low | 4 | 30 days |

## Required Fields

Every drift item should record:

- workspace,
- HCP run ID,
- Azure DevOps work item ID,
- Azure resource ID,
- category,
- classification rule,
- severity,
- SLA date,
- owner,
- ADO area path,
- detected date,
- expected state,
- actual state,
- decision,
- remediation link,
- exception expiry if applicable.
