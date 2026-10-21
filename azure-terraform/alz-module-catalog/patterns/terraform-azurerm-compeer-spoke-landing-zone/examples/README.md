# Spoke Capability Examples

These are complete reference configurations, not approved Compeer deployment values.
They use the catalog blueprint and its local module sources. They do not create
subscriptions, compute, a hub, central LAW, Sentinel, Defender pricing, budgets or locks.

## Select A Variant

Use `baseline.tfvars` plus **exactly one** variant. Objects are replaced, not deep-merged.

| Variant | Resources And Ownership |
| --- | --- |
| phase-one | Private audited vault, UAMI and network foundation; optional services off |
| all-optional-off | Approved secretless application: no vault/storage/telemetry/alerts/backup |
| production-create | Private ZRS Blob storage, dedicated vault, new application telemetry, new failed-request rule and separate on-call group |
| new-telemetry-shared-alert-routing | New component/rule, approved platform action group reused |
| nonproduction-private-telemetry | Dev resilience/volume defaults; private-only telemetry requires an existing approved AMPLS path |
| reuse-observability | Existing application/environment component, failed-request alert, routing and independently managed audit settings referenced without mutation |
| existing-vm-backup | Existing VMs enrolled into an existing approved same-subscription Recovery Services policy; no compute or vault provisioning |

The baseline includes naming, stable creation metadata, governance tags, explicit
IPAM inventory, inspected routes, private-agent access, a subnet rule, central DNS
and LAW IDs, platform contact outputs and scoped Entra group access. Each variant
shows complete relevant capability values. Use separate production/non-production
subscriptions, state/workspaces, approved IPAM allocations, identities and recipients.
The sample addresses are reusable TEST fixtures, never a cross-environment allocation.

## Review And Run

1. Replace every synthetic UUID, range, NVA/DNS IP, name, contact, principal, cost code,
   workspace reference and metadata value. Verify real platform public-contract versions.
2. Keep `enabled=false` until network, security, application and operations approvals.
   Phase 2 telemetry/data extensions are opt-in, not activated by the Phase 1 defaults.
3. Configure Azure/HCP authentication outside tfvars. Pin providers in the root lockfile
   using your approved platform matrix; initialize the local modules and public providers.
4. Use a dedicated state/backend per application/environment. Apply the foundation,
   then the central attachment workspace for both peerings and required VNet/DNS links.
5. Enable only after plan review and the explicit approval gate. No secret values belong in tfvars.

```bash
terraform init
terraform validate
terraform plan -var-file=baseline.tfvars -var-file=variants/production-create.tfvars
# After replacing inputs and obtaining approval, review an ENABLED plan:
terraform plan -var-file=baseline.tfvars -var-file=variants/production-create.tfvars \
  -var=enabled=true -var=deployment_approved=true
```

The first disabled plan creates nothing; it is not validation of Azure availability,
permissions or enabled resource behavior. The package test runner executes each actual
variant with mock providers and enabled approval, plus disabled/approval-denied runs:

```bash
bash implementations/workload-lz/test.sh
# From the alz-module-catalog root; uses local modules and mock providers only.
```

For the existing HCP workload roots, put these capability objects **inside `spoke`**:
`key_vault`, `diagnostics`, `monitoring`, `operations`, `storage_accounts`, `backup`.
The example runner exposes them as separate root variables only to compose baseline
and variant files without relying on nonexistent deep-merge semantics.

## Reuse And Lifecycle Safety

A shared LAW is normal; Application Insights reuse is only for an already approved
same-application/environment component. Share action groups only when the audience,
escalation and access are appropriate. Dedicated application vaults remain the default;
disable one only when no application secrets/keys/certificates require it. Do not reuse
the broad platform vault for application secrets.

`diagnostics.enabled=false` disables creation, not mandatory audit coverage.
Every enabled vault/storage target must reference an actual compliant setting.
Canonical diagnostic IDs end in `/providers/Microsoft.Insights/diagnosticSettings/NAME`,
not AzureRM's Terraform `TARGET|NAME` representation. Explicit categories are required.
A root storage setting covers metrics; Blob read/write/delete auditing targets the child service.

**Reuse does not import resources, adopt state or transfer ownership.**
The reuse variant is for parents already in this state with external settings already
present. For an existing Terraform-owned setting/rule/component, setting creation to
false or removing the resource schedules destruction. First arrange an approved
state handoff without destroying Azure resources, confirm the receiving owner and
check the saved plan for zero unintended destroys. Disabling a previously deployed
vault/storage capability is also a deletion request, not a pause switch.

Run the read-only live verifier against actual output after central attachment:
```bash
terraform output -json spoke | python ../integration-tests/verify_spoke.py
```
For an enabled vault on a network-connected runner, add `--private-dns`.
The optional secret probe needs separately approved temporary operator access and
a managed-identity-capable runner. A secretless variant must not request vault probes.

Mock tests are not live acceptance: confirm both peerings Connected, private DNS,
actual reuse IDs/category/destination coverage with no duplicates, telemetry ingestion,
notification delivery, effective routes/NVA symmetry and a restore test where relevant.
No AMPLS, application instrumentation, firewall rules or backup restore evidence is fabricated here.

## Microsoft Guidance

- [Key Vault security and application/environment isolation](https://learn.microsoft.com/en-us/azure/key-vault/general/secure-key-vault)
- [Workspace-based Application Insights using an existing LAW](https://learn.microsoft.com/en-us/azure/azure-monitor/app/create-workspace-resource)
- [Diagnostic settings, destinations and resource-specific support](https://learn.microsoft.com/en-us/azure/azure-monitor/platform/diagnostic-settings)
- [Landing-zone subscription vending and networking ownership](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/subscription-vending#configure-networking)
