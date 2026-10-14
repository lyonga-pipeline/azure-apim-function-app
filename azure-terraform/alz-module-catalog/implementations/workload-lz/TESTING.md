# Verification Record

Local verification completed on 2026-10-14. This is implementation/test evidence,
not Azure deployment evidence or stakeholder acceptance sign-off.

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
| Shared Application Insights module | Regression suite | 1 passed |
| Shared budget module | Regression suite | 2 passed |
| Shared action-group module | Regression suite | 3 passed |
| Shared metric-alert module | Regression suite | 1 passed |
| NET-22 pure Azure hub-spoke-peering pattern | Reciprocal peering, names, gateway/DNS/subscription guards | 10 passed |
| Legacy network-peering HCP adapter | Input resolution, public-output-only consumption and compatibility | 5 passed |
| Canonical private-endpoint module | Connection, DNS and validation regression suites | 11 passed |
| Canonical user-assigned-identity module | Identity outputs and validation regression suite | 9 passed |
| Integration verifier and deployment guard | Offline Python tests | 18 passed |

Total: 130 Terraform mock tests and 18 offline Python tests, all passing.
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

Local tools: Terraform 1.11.4, AzureRM 4.81.0, TFE 0.82.0 in workload roots
(0.80.0 in the legacy peering adapter), time 0.14.2 and
Python 3.9.6. CI also runs the new root/blueprint tests and fixture validation;
CI itself and its TFLint/Checkov/secret-scan jobs were not executed locally.
Existing Application Insights module inputs emit AzureRM deprecation warnings
for older disabled/enabled argument names. These are warnings under the pinned
AzureRM 4.x range, not failed validation or tests; a separate provider-v5 migration
must update that shared API without breaking its existing consumers.

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
