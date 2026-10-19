# Verification Record

## Current Shared-Service Reuse Verification: 2026-10-19

Updated the blueprint and both adapters to reference approved platform action
groups and optionally reuse existing application/environment Application Insights
components. Creation and delegated telemetry-role management are explicit;
shared resource configuration remains with its original owner. See [REUSE.md](REUSE.md).

| Suite rerun | Result |
| --- | --- |
| Spoke blueprint, actual catalog composition with mocked Azure | 72 passed |
| Production / non-production roots, including public-output shared-service reuse | 3 + 3 passed |
| Dedicated workload Key Vault / reciprocal peering | 8 + 10 passed |
| Shared role assignments / action groups / Application Insights | 8 + 3 + 3 passed |
| Shared metric alert / budget | 1 + 2 passed |
| Offline integration verifier, deployment guard and file-layout checks | 29 passed |

Total rerun: **113 Terraform mock tests and 29 offline Python tests passed** on
Terraform 1.11.4. Both roots and the isolated fixture pass terraform validate
without errors/warnings; scoped formatting, shell syntax and git diff --check
also pass. Historical suites below not listed here were not rerun for this change.

New coverage checks existing-ID/key reuse without duplicates, missing-key
failure, explicit create requirements, conflicting create/reuse choices, wrong
LAW/component IDs, externally owned telemetry with opt-in scoped access, and no
unused contacts/operations RG. The offline verifier additionally rejects disabled
groups, wrong alert-component scopes and wrong budget notification audiences,
while preserving an existing telemetry owner's sampling choice.

No Azure apply, state handoff, permission change, live notification or ingestion
probe was performed. Mocked cross-subscription references do not establish live
authorization or delivery. All client acceptance gates remain pending; held
activation examples remain commented and both templates remain disabled.
An existing owned component/group needs the documented explicit creation flags
to retain ownership; changing it to reuse is not an automatic safe migration.

## Historical Design-Alignment Verification: 2026-10-17

Checked the v13 design, v4 component workbook, refined placement worksheet,
detailed network deployment document and IAC-10 contract draft. Traceability,
holds, ownership and unresolved approvals are in [DESIGN-ALIGNMENT.md](DESIGN-ALIGNMENT.md).

| Suite rerun | Result |
| --- | --- |
| Spoke blueprint: actual catalog composition with mocked providers | 60 passed |
| Naming: legacy defaults plus Appendix F workload opt-in | 60 passed |
| Production and nonproduction roots, including disabled placeholders and public governance/LAW/RG passthrough | 2 + 2 passed |
| Separate workload Key Vault | 8 passed |
| Reciprocal peering pattern | 10 passed |
| Legacy workload-spoke compatibility | 6 passed |
| Shared tags / NSG modules | 47 + 3 passed |
| Offline integration verifier, live-deployment guard and file-layout tests | 24 passed |

Total: **198 Terraform mock tests and 24 offline Python tests passed** on
Terraform 1.11.4. Both workload roots and the isolated live fixture passed
terraform validate with zero errors/warnings. Tests cover held-service omission,
placement names, governance tag contracts, specific NVA routes, disabled BGP
propagation, Sunstream isolation, duplicate-route rejection and optional-service
security. Formatting, shell syntax and diff-whitespace checks were also run.

No Azure apply or live data-plane/route/ingestion probe was performed. All client
acceptance gates below remain pending; optional telemetry holds do not waive
R3.4. Existing-state RG replacements and optional-resource removals require a
reviewed HCP plan and migration, not an automatic apply.

## Historical Verification: 2026-10-14

Local verification completed on 2026-10-14. This is implementation/test evidence,
not Azure deployment evidence or stakeholder acceptance sign-off. The following
counts describe that earlier snapshot, not the current results above.

## Results

| Deliverable | Suite | Result |
| --- | --- | --- |
| 204092 / WKL-01 spoke blueprint | Real local modules, mocked Azure; profiles, operations, private storage, backup integration, explicit NET-29/IAM-06 conformance and negative cases | 34 passed |
| 204094 / NET-23 production root | Disabled placeholders; enabled public-contract consumption | 2 passed |
| 204114 / NET-24 non-production root | Disabled placeholders; enabled public-contract consumption | 2 passed |
| 204117 / WKL-07 separate workload vault | Private access, RBAC scopes, security parity and validation | 8 passed |
| Shared Key Vault module | Regression suite | 4 passed |
| Shared VNet module | Regression suite | 4 passed |
| Legacy workload-spoke pattern | Compatibility regression suite | 6 passed |
| Shared storage-account module | Security/recovery regression suites | 28 passed |
| Shared Application Insights module | Regression suite; null/true/false inverse-input compatibility with non-deprecated provider attributes | 3 passed |
| Shared budget module | Regression suite | 2 passed |
| Shared action-group module | Regression suite | 3 passed |
| Shared metric-alert module | Regression suite | 1 passed |
| NET-22 pure Azure hub-spoke-peering pattern | Reciprocal peering, names, gateway/DNS/subscription guards | 10 passed |
| Legacy network-peering HCP adapter | Input resolution, public-output-only consumption and compatibility | 5 passed |
| Canonical private-endpoint module | Connection, DNS and validation regression suites | 11 passed |
| Canonical user-assigned-identity module | Identity outputs and validation regression suite | 9 passed |
| Integration verifier and deployment guard | Offline Python tests | 18 passed |

Total: 132 Terraform mock tests and 18 offline Python tests, all passing.
All 16 Terraform suites above were rerun after the review refinements.
Terraform validate passed for both environment roots, the separate vault pattern
and the live fixture. The blueprint's provider aliases were validated through
both environment roots and the fixture. Formatting checks, shell syntax,
workflow YAML parsing and tracked-diff whitespace checks passed. The dependency
graph confirms hub gateway-transit permission precedes spoke remote-gateway use.
The new workload Terraform sources contain no lock resource, module or toggle.
The existing central platform-network-peering root also passes validation with
the independently scoped DNS alias. The pure peering core/spoke fixture have no
TFE provider or API-token dependency; HCP reads are confined to the adapters.
Tests confirm both real environment roots select their respective profile and
persist a correct first-of-month budget date with different approved amounts.

Supported Step 11 baseline and local tools: Terraform 1.11.4, AzureRM 4.81.0, TFE 0.82.0 in workload roots
(0.80.0 in the legacy peering adapter), time 0.14.2 and
Python 3.9.6. New Step 11 patterns/adapters require Terraform >=1.11.4 and <2;
catalog CI pins 1.11.4 instead of floating to latest. This sets a verified
support boundary; the reported Terraform 1.7 mock failures were not reproduced
or diagnosed here. CI also runs the new root/blueprint tests and fixture validation;
CI itself and its TFLint/Checkov/secret-scan jobs were not executed locally.
Application Insights now uses daily_data_cap_notifications_enabled,
ip_masking_enabled and local_authentication_enabled internally. Tests preserve
the legacy module input meanings, defaults and inverse output contract; its
provider floor is now 4.81 without enabling provider v5. Validation returned
zero errors/warnings in all six checked entry points (both workload roots,
vault pattern, live fixture, central peering root and Application Insights
module). Unrelated shared-module/provider-v5 API migrations remain out of scope.

## Review Follow-Up

The workspace catalog now identifies both Step 11 roots and marks the legacy
workload root compatibility-only. HCP output-read permissions are documented
separately from full remote-state sharing; no HCP access settings were changed.
Microsoft.Consumption is included in the bounded registration list for both
workload roots and the isolated fixture. No Azure registration was executed.
The [client acceptance runbook](ACCEPTANCE.md) separates read-only deployed-spoke
checks from the optional billable fixture. Real IPAM, CSP readiness, recipients,
positive budgets and live connectivity/sign-off remain deployment gates. Locks
remain removed, as requested, and onboarding/vending ownership is unchanged.

## Repeat Locally

From each pattern, module or workspace directory listed above:

```bash
terraform init -backend=false -input=false -lockfile=readonly
terraform test -no-color
```

Run terraform validate in the environment roots, vault pattern and live fixture.
The blueprint requires the provider aliases supplied by its callers/test mocks.
From patterns/terraform-azurerm-compeer-spoke-landing-zone/integration-tests:

```bash
bash -n run.sh
python3 -m unittest -v test_verify_spoke.py
```

Do not execute run.sh merely to run the offline tests. Its explicit approval
guard protects a separate, billable live deployment workflow.

## Deployment Gate

Both committed environment examples remain enabled=false with placeholders.
Resource locks have been removed from the new workload templates. No Azure
apply or live data-plane probe was performed.
Replace placeholders with approved IPAM, subscription, HCP, identity and routing
values before deployment. Use the integration-tests README for the isolated
live fixture, cleanup requirements and optional private managed-identity probe.

Before client acceptance, validate real reciprocal peering, hybrid DNS,
application rules/effective routes, inspected egress, private secret access,
central log ingestion, Defender/flow-log policy convergence and stakeholder
sign-off. Mock tests do not establish those runtime properties.
Also validate telemetry SDK/managed-identity ingestion, approved operational
recipients, actual cost notifications, private Blob DNS/data access when used,
and actual backup/restore of supplied VMs. Profile settings are starting defaults,
not evidence of an application SLO or successful recovery exercise.
