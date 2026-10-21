# Workload Landing Zone Verification

The repository uses local catalog modules. The HCP-pinned Compeer copy is kept
outside this repository; it is not a second checked-in source tree. Blueprint,
vault, central attachment, workspace and example behavior are aligned between
the copies. Dependency sources and environment-specific runbooks intentionally
differ. No private registry fixtures or downloaded module caches are published.

## Run The Regression

From `azure-terraform/alz-module-catalog`:

```bash
bash implementations/workload-lz/test.sh
```

Use stable Terraform >=1.11.4, <2.0.0 and Python 3. The script rejects older Core
versions before initialization. Check `type -a terraform` and `terraform version`
when a directly invoked old binary, alias or PATH entry overrides tfenv.
AzureRM >=4.81, <5 is required; committed root lockfiles select the tested
providers. Public provider download access or an approved cache is needed.
Private Compeer module registry access is not required for this catalog run.

The script runs:

- Blueprint positive/negative mock integration tests and all capability flags.
- Workload vault, paired peering core and central attachment adapter tests.
- Shared adapter and production/non-production workspace tests.
- Central network-peering workspace tests and complete-root validation.
- Local naming, VNet, storage, telemetry, vault, peering and DNS-link helper tests.
- Seven actual example tfvars variants with disabled, approval-denied and enabled
  composition runs for each, not a separate test-only copy of the inputs.
- Python observed-state verifier, private probe and source-layout tests.
- Example/live-fixture init and validate plus live-driver shell syntax checking.

The same script runs in `.github/workflows/alz-catalog-ci.yml`. It does not invoke
the billable live-test driver or `terraform apply`. Native test apply operations
use only the suites' mock providers, never an Azure deployment.

## Latest Verification

Verified on 2026-10-21 using Terraform 1.11.4 and AzureRM 4.81.0 in a
disposable catalog copy, without changing provider constraints or deploying Azure.

| Check | Result |
| --- | --- |
| Blueprint | 89 passed |
| Workload vault | 12 passed |
| Paired peering / central adapter | 10 / 25 passed |
| Shared / production / non-production / central workspace | 3 / 3 / 3 / 2 passed |
| Local helper tests | 104 passed |
| Seven actual tfvars variants | 21 passed |
| Total Terraform tests | 272 passed, 0 failed |
| Python verifier, private probe and source layout | 37 passed, 0 failed |
| Normalized HCL comparison with the local Compeer copy | 69 files matched |

Complete workspace roots, examples and the isolated live fixture also initialized
and validated successfully. Formatting, shell syntax and whitespace checks passed.
This is local/mock evidence, not a completed GitHub Actions run or live acceptance.

## Compatibility Regressions

The network module receives `local.network_subnets`, the exact security input
map checked by the blueprint tests. Tests do not assume that an HCP VNet exports
default outbound access or endpoint network policies in its subnet output.
The live verifier separately checks Azure's actual `defaultOutboundAccess`
and `privateEndpointNetworkPolicies`, rejecting unsafe or missing values.

Storage receives `local.storage_settings`. Tests check the actual module input
contract instead of the absent HCP `security_configuration` output. Local helper
tests independently check resource wiring for private/keyless access, TLS,
firewall, encryption, versioning and production/non-production recovery values.
Both storage calls retain the required `resource_group_name` and `location`
arguments; these are not fields of storage_settings. Tests verify the actual
resource group and location outputs. The catalog helper may publish additional
observed outputs; the blueprint does not depend on those extra fields.

The workload vault collects observed `private_dns_zone_configs` from its private
endpoint helper. Its security output comes from the local Key Vault helper's
resource attributes, not desired constants or a permissive fallback. The reported
HCP Key Vault 1.0.0 lacks this extra output, so the Compeer copy also keeps that
helper local pending a verified new registry release.

## Ownership And Lifecycle

The blueprint publishes attachment contract 2.0.0 with naming context but no
peering or VNet DNS-link names. The central attachment state owns those names,
both peering directions and required links. No hub-write provider is needed by
the spoke state. Tests cover v2 public output consumption, backward-compatible
v1 names, explicit central overrides, paired gateway intent and secretless spokes.

Vault opt-out and per-storage/backup enable flags are supported. Enabled vault
and storage resources still require managed or explicitly externally managed
central audit coverage. Reuse checks cover exact parent IDs, Blob child targets,
required categories and workspace destinations. Telemetry, alert and action-group
reuse never imply import, state ownership transfer or fallback creation.

Budgets and resource locks are absent from this Phase 1 blueprint. Existing
budgets or changed resource ownership require a reviewed migration/handoff;
removing configuration or setting enabled=false can plan destruction. Moved
blocks preserve only documented unchanged ownership transitions. No real state
migration, import or Azure apply is part of this regression.

## Live Acceptance Gates

Mock success is not production approval or certification of private registry
releases. In the Compeer environment, initialize/test the actual pinned releases
separately. For Azure acceptance use the isolated, explicitly approved driver
documented in the blueprint's `integration-tests/README.md`; it is never run by
the regression script or pull-request CI.

Before enabling a real workload, obtain approved application/IPAM/tenant/
subscription/DNS/NVA/tag/access values, scoped producer-output read access and
separate environment run identities. After foundation and central attachment,
verify Connected peerings, private DNS/access, actual audit settings and ingestion,
alert delivery, NVA route symmetry and backup restore evidence where applicable.
No live Azure acceptance evidence is claimed by the local tests.
