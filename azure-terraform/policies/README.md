# Policy And Guardrails

This directory contains the HCP plan-policy foundation for the net-new landing-zone path.

Policy is split into two deployment lanes:

| Layer | Purpose | First rollout posture |
| --- | --- | --- |
| OPA policy checks | Pre-apply checks against Terraform plans in HCP workspaces | Advisory for pilot, then blocking for net-new LZ |
| Azure Policy | Runtime guardrails at management-group or subscription scope, deployed from `landing-zones/net-new-hub-spoke/global-governance` | Audit for pilot, then Deny for selected net-new scopes |

Existing projects should not receive blocking policy attachment until remediation readiness is confirmed.

## Policy Domains

Initial controls focus on low-regret enterprise standards:

- approved Azure regions,
- required enterprise tags,
- no unmanaged public IP creation,
- private-by-default storage,
- private-by-default Key Vault,
- private-by-default SQL,
- private-by-default App Service and Function App,
- HTTPS/TLS posture,
- diagnostic routing expectations.

Diagnostic automation can be added later as DeployIfNotExists or Modify policy once ownership, managed identity permissions, and exception handling are finalized.
