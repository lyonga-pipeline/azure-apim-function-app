# Explicit Holds

**PHASE2 NEW tracking, not deployment authorization.** These workbook rows are explicitly Phase 3 or lack prerequisite design approval. No public ingress, resource locks, subscription creation or repo seeding is enabled by this delivery.

| Row | Hold | Release criteria |
| --- | --- | --- |
| 1.4 IAC-04 | HCP team/workspace RBAC | Phase 3; excluded from this delivery. Requires an approved state-access model and least-privilege team matrix. |
| 4.5 NET-35 | Application Gateway + WAF | Phase 3 ingress approval, threat model, WAF policy, certificates, health probes, dedicated subnet, scoped public-IP exemption with expiry. Existing base modules can be composed then; no speculative gateway/public IP is created now. |
| 4.6 NET-40 | Cloudflare/App Gateway failover | Approved DNS TTL/cutover/rollback, continuously valid certificates, equivalent authentication/authorization on both paths, named incident authority and scheduled failover exercise. |
| 9.4 IAC-11 | Repo seed/workload onboarding | Phase 3; excluded from this delivery. Requires approved ADO templates/pipelines, HCP projects/teams/policy sets, pinned releases, ownership metadata and secure credential process. |
| 9.1 GOV-04 | Subscription vending | CSP/billing approval. Use existing governance onboarding for already-vended subscriptions meanwhile. |

Open decisions (OBS-09, OBS-08, NET-30, NET-32, SEC-08, PLT-03/04/05 and GRC scope) remain opt-in. Empty maps and disabled roots prevent those decisions from changing existing deployments.

## Future Composition (Comments Only)

```hcl
# ON HOLD Phase 3: compose approved existing base Application Gateway / WAF modules.
# First create a narrowly scoped, justified, approved, expiring GOV-11 exemption.
# Do not relax the enterprise deny-public-IP assignment globally.
#
# EXCLUDED Phase 3 IAC-11: no repository/team/workspace bootstrap resources or
# enablement flags are included. Design and implement separately after approval.
```
