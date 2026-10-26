# Internal Applications Non-Production

This root calls the pinned spoke blueprint directly and owns a separate state.
`terraform.tfvars` remains the disabled Phase 1 starting configuration.

## Complete Configuration Examples

| File | Application services | Audit settings |
| --- | --- | --- |
| [create-new.tfvars.example](create-new.tfvars.example) | New Application Insights component, failed-request alert and application action group | Created here for the dedicated vault, storage account metrics and Blob service logs |
| [reuse-existing.tfvars.example](reuse-existing.tfvars.example) | Existing same-application/UAT component, alert and its action-group routing | Explicit existing settings remain externally owned; audit coverage is still required |

Both examples are complete HCL variable files with **synthetic values**, not
approved production inputs. They deliberately set `spoke.enabled = false` and
use `environment = "uat"`. Both select ZRS storage and 30-day soft deletion.
The create profile also configures 100% sampling and a sample five-failure
threshold, retaining the non-production severity 3/five-minute alert profile.
The reuse profile leaves the existing component/alert settings with their owner;
verify their effective sampling, threshold and routing rather than assuming the
local environment profile configures those external resources.
Actual production deployments must use `../workload-internal-apps-prod`; this
root rejects `environment = "prod"`.

These are alternative starting profiles, not an instruction to rename an existing
dev/test deployment to UAT. Keep an existing state's environment, appcode, network
allocations and resource names; provision a separate approved root/backend/HCP
workspace for a different environment.

Telemetry, workload alerts and workload storage remain opt-in extensions subject
to their component/phase approvals. An example is not authorization to activate
deferred services. Budgets, management locks and compute are not added.

## Create And Reuse Boundaries

| Resource | Ownership and selection |
| --- | --- |
| Spoke RGs, VNet, subnets, NSGs, routes and workload UAMI | Created/owned by this workload state; neither example adopts existing networking |
| Dedicated workload Key Vault and Blob accounts | Create or retain here, or disable when not required. No existing-vault/account reference mode is exposed |
| Central LAW, DNS zones, hybrid DNS, optional existing DDoS plan | Reused from the approved management/connectivity contracts; not created here |
| Application Insights | `create_application_insights = true` **or** `existing_application_insights`, never both |
| New alert routing | Explicitly create an app action group, select `platform_action_group_keys = ["primary"]`, or supply approved `action_group_ids` |
| Existing failed-request alert | Set `create_failed_requests_alert = false`, supply the alert/component/action-group IDs, and leave new `operations` routes empty |
| Diagnostics | Create with `diagnostics.enabled = true`, or register exact existing settings with their central LAW and required categories. `false` does not remove the audit requirement |
| Backup | Optional VM registration into an existing workload-subscription vault/policy; the blueprint creates neither compute nor the vault/policy |
| Hub attachment | Central attachment owns both peerings and VNet-to-zone links; `manage_hub_attachment` stays false |

The new-services example also shows how to reuse the platform action group while
still creating a dedicated application component and alert. Reuse an Application
Insights component only for its approved application/environment, not across
unrelated apps or between production and non-production. Its external owner must
verify workspace linkage, authentication, network access and UAMI publishing
rights. Creation-only sampling/network knobs do not reconfigure reused resources.

## Select One Example

From this directory, initialize and inspect exactly one profile:

```bash
terraform init -backend=false -input=false
terraform validate
terraform plan -var-file=create-new.tfvars.example
# Alternatively, not in addition:
terraform plan -var-file=reuse-existing.tfvars.example
```

The plan commands leave the examples disabled. An enabled plan requires real
Azure/HCP credentials and an initialized approved backend. `-backend=false` is
for local module/test initialization; it does not configure a deployment backend.
Before enabling, replace all synthetic UUIDs, names, IP ranges, principals,
contacts and business metadata; confirm the HCP organization/workspace names and
scoped access to their non-sensitive outputs. The reused component/diagnostic
LAW IDs must exactly match the real management contract. Confirm the central
attachment, private DNS, NVA egress and any AMPLS path before live acceptance.

Do not use both files together. Terraform replaces the **whole** `spoke` object
with the last supplied value; it does not deep-merge nested objects. These files
are not auto-loaded because they end in `.example`. In HCP, place the reviewed
configuration in that environment root's `terraform.tfvars`, or supply the full
`spoke` value as one Terraform/HCL workspace variable. Keep actual identity and
subscription context in the approved environment-specific variable set.

## Existing State Safety

The reuse example assumes its enabled vault/storage parents already belong to
this workload state and the declared diagnostics already exist under a separate
approved owner. It does not import parents, validate live settings, or hand over
ownership. Do not disable an owned service, change to a reused reference or turn
`spoke.enabled` off as a pause mechanism: these changes can plan destruction.
Use a separately reviewed resource-preserving state handoff where required, then
review the plan for replacements/deletions. See [reuse guidance](../../REUSE.md).

## Local Example Tests

These commands test the actual example inputs against the pinned child modules
with mocked Azure/HCP providers, including an enabled run and the production
environment guard. They make no Azure changes and do not verify live access:

```bash
terraform test -test-directory=example-tests -var-file=create-new.tfvars.example
terraform test -test-directory=example-tests -var-file=reuse-existing.tfvars.example
```
