# Internal Applications Non-Production

This root calls the pinned spoke blueprint directly and owns a separate state.
`terraform.tfvars` remains the disabled Phase 1 starting configuration.

## Publish Context Before Central Peering

This VNet-owning root publishes `context` directly from `module.blueprint[0].context`, alongside `attachment_contract` v2. The central attachment workspace reads the saved HCP outputs, not un-applied code. Existing `spoke.context` consumers remain supported; the explicit output also supports thin deployment roots that publish only the individual VNet accessors.

If peering fails the `tenant`, `subscription` and `environment` producer checks while the VNet ID resolves correctly, verify this producer has a non-null public `context`. Add the `context` block from [outputs.tf](outputs.tf) to an older producer root, then review/apply that producer's output change in its existing workspace. Do not upgrade the blueprint, rename resources or manufacture context values in the peering root just to bypass the checks.

Match the peering root's `naming_context` exactly to the producer's saved `attachment_contract.naming_context` (`region`, `environment`, `domain`, `appcode`). A mismatch such as `ptinapp` versus `pltinapp` must be corrected in the reviewed consumer inputs; the immutable attachment map key need not change. Then restore the peering `producer_contract` precondition and re-plan. The attachment module needs no change or registry release for this root-output addition. Stop if the producer plan includes unrelated Azure changes; publishing an output is not approval for those changes.

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

## Two-Subnet Dev Pilot

The pilot is not a two-subnet limit. In `spoke.subnets`, freely add `app`,
`data`, `presentation` or other approved purpose keys. Set
`spoke.private_endpoint_subnet_key` only when using a key other than the default
`private_endpoints`. All entries receive generated names, an NSG and an inspected
route table. Keep existing deployed keys unchanged to avoid resource replacement.

This root also accepts `environment = "sandbox"` or `"sbx"` in a separate
sandbox workspace/state. Both use the `sandbox` naming/tag token and require
`spoke.workload_tags.expiration_date`. See the blueprint's complete
[sandbox/subnet example](../../../../patterns/terraform-azurerm-compeer-spoke-landing-zone/examples/variants/sandbox-flexible-subnets.tfvars);
its example-runner capability objects must be placed inside `spoke` for this root.

[pilot-two-subnets.tfvars.example](pilot-two-subnets.tfvars.example) corrects the
supplied pilot configuration while leaving the default `terraform.tfvars` unchanged.
It is disabled until the missing values and approvals are resolved.

| Item | Pilot configuration |
| --- | --- |
| VNet | Supplied `10.102.64.0/27`, subject to IPAM confirmation |
| Application subnet | `10.102.64.0/28` |
| Private-endpoint subnet | `10.102.64.16/28`; a non-empty prefix is mandatory |
| Data subnet | Not created. These two `/28`s consume the entire `/27`; storage uses a private endpoint, not a data subnet |
| HTTPS rule | Destination corrected to the application subnet instead of unrelated `10.200.0.0/24` |
| Alert routing | Reuses the management output's enabled `primary` action group; an explicit empty selection does not trigger fallback |

The file preserves the supplied vault, ZRS Blob storage, Application Insights and
failed-request alert selections. It is **not network-only**. For a new network-only
deployment, set vault/storage `enabled=false`, monitoring `enabled=false` and
`alerts_enabled=false`, and leave the operations routing empty before the first
apply. Do not disable previously managed resources to pause them.

Required before enabling this profile:

1. Supply real `tenant_id` and workload `subscription_id` using the existing HCP
   inputs or `TF_VAR_tenant_id` / `TF_VAR_subscription_id` locally. They are omitted
   from this file; blank or redacted IDs cannot authenticate Azure.
2. Supply the existing vault/blob zone ARM IDs through a scoped
   `private_dns_zone_ids` HCP Terraform/HCL variable set or root tfvars input
   when the connectivity outputs do not publish them. Manually created and
   legacy-owned zones are supported without changing their old code or outputs.
   There is no separate DNS provider; old DNS subscription inputs are ignored.
3. Replace `spoke.egress_next_hop_ip` with the confirmed hub NVA/frontend IPv4
   **string**. It is mandatory even for network-only deployment because the
   blueprint supplies inspected UDRs. The repository's current `10.102.4.42`
   reference is not proof of actual deployment or network approval.
4. Confirm the supplied client `10.40.10.0/24`, complete the IPAM/inspection
   inventory, verify hybrid DNS/LAW/vault/blob-zone outputs and confirm that the
   existing `primary` action group is the approved pilot audience.
5. Authenticate the workload identity and approve scoped zone read/join access
   for its endpoint DNS groups. Grant the scoped HCP output-read access for the
   retained platform metadata. A subscription reported as unknown
   by Azure CLI is an authentication/access/context problem, not a subnet error.

Use exactly this profile, not the create/reuse UAT profiles at the same time:

```bash
terraform plan -var-file=pilot-two-subnets.tfvars.example
```

The file's `spoke.enabled=false` leaves it inert. After supplying the required
values, approving the optional services and enabling it, review the full plan.
The central attachment workspace still owns both peerings and DNS VNet links;
the spoke does not establish live hub connectivity by itself.

Mock verification substitutes only the missing identity/DNS/NVA fixture values:

```bash
terraform test -test-directory=pilot-tests -var-file=pilot-two-subnets.tfvars.example
```

See [DNS ownership](../../DNS-OWNERSHIP.md) for the variable-set value, source
precedence, endpoint zone groups versus VNet links, and upgrade/permission checks.

## Create And Reuse Boundaries

For approved platform-owned DNS registration, add
`private_endpoint_dns_mode="policy"` and `policy_dns_registration_approved=true`
inside `spoke`. Zone IDs are then configured only in `platform-policy`, not
this root. Keep the default Terraform ownership for existing deployments until
the [state handoff and live acceptance](../../POLICY-DNS.md) are complete.

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
