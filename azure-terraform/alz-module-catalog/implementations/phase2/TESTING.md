# Phase 2 Verification

**PHASE2 NEW:** verified against the supplied v5 `Phase 2 Deployment Order` and independently cross-checked against `Component List` on 2026-10-31.

## Results

| Check | Result |
| --- | --- |
| Terraform Core / primary providers | 1.11.4 / AzureRM 4.81.0 / TFE 0.82.0 (new roots), 0.80.0 (retained existing-root locks) / Cloudflare 4.52.8 / AzAPI 2.4.0 (cross-root attachment tests) |
| Workbook and structural checks | 13 passed; 45 in-scope order activities, 4 Phase 3 exclusions, 4 additional Component List entries; canonical batch peering owners checked |
| New Phase 2 pattern tests | 34 passed |
| Existing spoke blueprint regression tests | 91 passed |
| Workload Key Vault regression tests | 37 passed |
| Existing platform/network/CSP pattern regressions | 132 passed |
| Additional governance/OIDC/Sentinel regressions | 92 passed |
| Action-group/storage/key/DES helper regressions | 70 passed |
| Eight canonical standalone roots, including five enabled pilot suites and the external-identity/batch handoff | 31 passed |
| Five existing-owner Phase 2 integration suites | 18 passed |
| Existing platform-policy workspace regressions | 36 passed |
| **Terraform total** | **541 passed, 0 failed** |
| Provider warning | Existing Sentinel Fusion `name` deprecation under AzureRM 4.x; retained for compatibility and tracked in REVIEW.md |
| Full catalog Terraform formatting, runner shell syntax and CI YAML parsing | Passed |

The runner initializes 40 configurations (22 patterns, five helpers, eight canonical standalone roots and five extended existing roots) using isolated temporary Terraform data directories. There are 47 test invocations, including five additional enabled-pilot invocations, the real external-identity-to-production-attachment root handoff and the retained platform-policy workspace suite. Root configurations are validated directly. Reusable patterns requiring provider aliases are validated through their mock caller tests and roots supplying those aliases. The obsolete phase-based deployment roots are removed; the runner discovers canonical owners through [implementation-map.json](implementation-map.json).

The companion `implementations/platform-lz/network-attachments/test.sh` suite also passed **115 Terraform tests and 18 operating/ownership checks**. It includes the same three cross-root handoff cases. Counts overlap between suites and must not be presented as unique tests.

## Reproduce

From the catalog directory, with Bash, Python 3 and Terraform >=1.11.4:

```sh
export PHASE2_WORKBOOK="/path/to/Azure_LZ_MVP_Component_List_v5.xlsx"
bash implementations/phase2/test.sh
terraform fmt -check -recursive modules patterns implementations
```

Set `TF_PLUGIN_CACHE_DIR` to an optional known-good cache. Initialization still requires provider registry access/downloads; mock tests require no Azure/HCP identity. Without `PHASE2_WORKBOOK`, two source-workbook comparisons are explicitly skipped (11 structural checks run). The source workbook remains outside the repository; CI runs the checked-in manifest/structure checks and all Terraform suites in `phase2-tests`.

## Coverage And Limits

Tests cover inert defaults and enabled pilots; private AMA DCE/DCR composition and reuse; routed KQL/native metric alerts; archive versioning/export/audit/no-deletion and feedback-loop guards; secret event/topic ownership; budgets/exports/anomalies; HCP setting preservation and context checks; Phase 3 exclusion; sandbox expiry; private spoke create/reuse; two external DCs with inspected routes/backups; central Bastion reuse; exact OIDC identities; Sentinel data-source/automation guards; and cryptographic key rotation.

Ownership integration tests additionally cover reuse of existing management outputs; public-only central LAW reads; network-owned probes; owner-keyed Windows/Linux VM agents; explicit AMA/association ownership confirmation; existing AMA reuse; disjoint policy/FinOps interfaces; duplicate policy/budget guards; and legacy external-DC ownership review. The original policy-workspace tests still run separately. Required pattern patch releases and safe adoption are documented in [ENGINEERING-HANDOFF.md](ENGINEERING-HANDOFF.md).

The external identity tests also cover disabled/no-read behavior, null-input backward compatibility, wrong tenant/subscription rejection, actual VNet CIDR output, exact v3 producer payload parity, two named production-owned peerings and optional DNS intent without identity-owned links. Terraform 1.11 requires literal mock overrides; the HCP response fixture is checked against the real producer output rather than assuming the fixture proves compatibility.

All tests use mocked providers. **No live Azure/HCP deployment, import, policy remediation, patching, secret rotation, failover or compliance acceptance was performed.** Existing deployed defaults and resource addresses were retained, but production no-change assurance still requires a real-state speculative plan. Never equate mock success with network reachability, RBAC propagation, KQL validity, successful export/retention, forest replication or application recovery.

The existing TFLint, Checkov and secret-scan CI gates remain configured. They were not executed locally in this verification; a local mock pass is not a claim that remote security scanning or the production plan has passed.

Required live gates remain in [RUNBOOKS.md](RUNBOOKS.md); Phase 3 and unresolved decisions remain in [ON-HOLD.md](ON-HOLD.md).
