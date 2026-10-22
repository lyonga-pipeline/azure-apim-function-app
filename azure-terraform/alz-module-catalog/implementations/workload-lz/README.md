# Internal Applications Workload Landing Zones

See [STEP11.md](STEP11.md) for all seven component mappings and the peering
code/state ownership decision. [DESIGN-ALIGNMENT.md](DESIGN-ALIGNMENT.md) records
the actual v13/v4/refined-placement review, source conflicts and holds.
The selected central attachment model and migration steps are in [ATTACHMENT.md](ATTACHMENT.md).
See [REUSE.md](REUSE.md) for platform-service reuse, explicit creation choices
and existing-deployment migration cautions.

| Ticket | Artifact |
| --- | --- |
| 204092 / WKL-01 | patterns/terraform-azurerm-compeer-spoke-landing-zone |
| 204094 / NET-23 | workspaces/workload-internal-apps-prod |
| 204114 / NET-24 | workspaces/workload-internal-apps-nonprod |
| 204117 / WKL-07 | Separate workload-key-vault pattern, embedded by default |

Each workspace root calls an independently pinned release of the same typed
blueprint directly. Public-contract reads and stable deployment metadata live
in the root; network/security implementation stays in the reusable pattern.
The live `shared/` adapter is deprecated and no longer consumed by these roots.
See [ISOLATION.md](ISOLATION.md) for trunk-based release promotion, exact HCP
working-directory/trigger settings and existing-state migration. The unrelated
legacy platform-workload-spoke root/pattern remains unchanged.

## Supported Toolchain

Use Terraform 1.11.4 in HCP and on the VDI. The new patterns and adapters require
>=1.11.4 and <2; CI is pinned to 1.11.4 rather than an untested floating latest.
The floor reflects the verified test baseline, not a claim about the cause of
the reported Terraform 1.7 mock-test failures. AzureRM >=4.81 and <5 is required.
The shared Application Insights module retains its caller API while replacing
the provider's deprecated inverse booleans internally. Existing consumers with
older provider locks need a reviewed init -upgrade and plan before applying.
Workspace paths are listed below and in [HCP-WORKSPACES.md](../platform-lz/HCP-WORKSPACES.md).
The catalog pattern uses local child modules; deployment roots fetch its fixed
commit archive, including those children. The HCP-pinned Compeer copy stays outside
the repository and requires its own verified blueprint publication before adopting
registry-based root pins. Run `bash implementations/workload-lz/test.sh` from the catalog
root for the same capability, ownership, workspace and example coverage.

## Replace Placeholders Before Enabling

The committed terraform.tfvars files intentionally have enabled=false. Replace:

1. HCP organization and exact management/connectivity/governance workspace names.
2. Approved application code, application/owner, source repository, cost center,
   classification, criticality and DR requirements.
3. IPAM-approved VNet/application/private-endpoint subnet CIDRs and the complete
   relevant reserved/on-prem/other-spoke range inventory.
4. Network-approved firewall/NVA next-hop IP. Route Server's own IP is NOT a
   firewall next hop. Hybrid DNS IPs come from the connectivity contract unless
   explicitly overridden in platform_inputs.
5. Approved operator/read groups and application ingress/inter-tier rules.
6. If activating commented-out optional operations, reuse approved platform
   action-group keys/existing IDs, or explicitly authorize a new application
   group with create_action_group=true and recipients. Explicitly create or
   reuse the approved application/environment telemetry component, supply
   actual SLO settings. Budgets are removed from this Phase 1 package. OBS-09/OBS-04 remain
   off by default; R3.4 production coverage still requires security sign-off.

Set these as Terraform-category HCP variables, not secret values in tfvars:
tenant_id, subscription_id, connectivity_subscription_id and (if different)
private_dns_subscription_id. Configure dynamic credentials/approved run identity
and tightly scoped read access to the producers' non-sensitive outputs.
Do not grant full-state access just to obtain resource IDs. Setting
use_tfe_outputs=false requires complete approved platform_inputs instead.

tfe_outputs requires a valid approved HCP token with output-read access on the
three producers; Azure dynamic credentials alone are not HCP API credentials.
Keep any TFE_TOKEN sensitive and out of Git. Remote-state-sharing permissions
do not apply to this data source, so do not broaden state sharing to troubleshoot
empty outputs. Verify exact workspace names, token permissions, completed
producer applies and non-sensitive root outputs instead. See
[HashiCorp's distinction](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/state#data-source-configuration).

The spoke republishes workload resource-group IDs, the approved LAW ID and
governance mandatory_tag_keys for application roots. The governance list must
be readable/non-empty (or supplied explicitly in platform_inputs), and all its
keys must be present in workload tags. Applications need no platform-state read
grant just to obtain these values. The standalone blueprint defaults to the
shared tag module's standard when no governance list is supplied.

Production is fixed to prod. Non-production defaults to dev and accepts test,
uat and approved np1/np2/np3 aliases. Use a SEPARATE workspace/state per actual
application and environment, not one shared state for unrelated applications.
The ticket-root directories are templates for that per-application instantiation.
For independent promotion, give every app/environment its own directory and
module release pin, not just another workspace pointing to the same root.

HCP VCS working directories, relative to the repository:

```text
azure-terraform/alz-module-catalog/implementations/workload-lz/workspaces/workload-internal-apps-prod
azure-terraform/alz-module-catalog/implementations/workload-lz/workspaces/workload-internal-apps-nonprod
```

## Access And Ownership

The workload run identity needs workload RG/network/Key Vault/identity creation
permissions and separately approved, constrained role-assignment rights. It no
longer needs hub peering write permissions or a hub provider. Scope required
private-endpoint zone join/read permissions to the actual existing zone.
Hub/DNS resource providers must already be registered by their
owners; the workload provider explicitly registers required workload namespaces.
The bounded list excludes Microsoft.Consumption: this package creates no budgets.
The run identity needs approved register/action permissions for the listed
workload namespaces; registration does not grant resource-write permissions.
Keep policy assignment and privileged/PIM ownership with platform-policy and
the authorization workspace. No subscription creation, MG moves, enterprise
policy assignment, Defender pricing, central LAW, Sentinel or flow-log resource
is deployed from the spoke state.

The blueprint creates NO peerings or vault/Blob-zone VNet links. Keep
manage_hub_attachment=false; the separately approved platform attachment state
owns both directions and required links from the versioned public contract.
Apply foundation first, attachment second, then validate application connectivity.
Do not also deploy local half-peerings or duplicate private DNS zones.
An existing zone may be in the old connectivity
subscription; private_dns_subscription_id must point there, not automatically
to the new hub subscription.

The vault is created in this workload subscription's security RG. It is not
the shared platform vault. Supply secret_officer_group_ids explicitly; the
deployment principal does not automatically receive secret access. The workload
UAMI receives only vault-scoped Secrets User and still needs attaching to the app.

Defender and flow logging are inherited from platform-policy. Vault AuditEvent
is directly Terraform-managed and matches category DINE. Register the exact
vault diagnostic target with platform-policy when strict audit-only ownership
is required; do not exempt every Terraform-created resource automatically.

Lock resources and the locks_enabled option have been removed from these new
workload templates. Existing platform/legacy lock implementations are untouched.

## Environment And Service Configuration

Both roots deploy the same governed security baseline, but actual profiles differ:

| Configuration | Production | Non-production |
| --- | --- | --- |
| Optional Blob storage default | ZRS, 30-day deletion recovery | LRS, 7-day deletion recovery |
| Application telemetry sampling | 100% initial setting | 20% initial setting |
| Failure alert | Severity 1, PT1M evaluation, count 5 | Severity 3, PT5M evaluation, count 20 |
| Access groups, subscriptions and recipients | Independent production inputs | Independent non-production inputs |

Tune alert counts/sampling to actual application SLOs and use ZRS in staging
when testing production resilience. KV purge protection, private endpoints,
keyless storage, NSG/UDR enforcement and central security logging do not weaken.

Always-created foundation: network/security/app-purpose RGs,
VNet/subnets/NSGs/UDRs, workload UAMI,
and private Key Vault with audit diagnostics. The existing central LAW,
Sentinel, Defender/flow-log policies and hybrid shared services are reused.
Application Insights/alerts are Phase 2 opt-ins; the operations RG exists only
when a local telemetry component, action group or alert needs it. Reference-only
telemetry needs no empty operations RG.
Each root reads management's existing action_group_ids public output and
defaults to primary only when published/enabled and no explicit ID/local-create
choice is supplied. It does not modify shared contacts. Existing approved
Application Insights components can be referenced without taking ownership or
changing their settings; creation and delegated role management are explicit.
Budgets are not implemented in this package; Phase 2 ownership remains with
governance. Both roots comment out deferred telemetry activation examples.

Enable optional Blob stores ONLY for an application that needs them:

```hcl
storage_accounts = {
  data = { grant_workload_blob_access = true }
}
```

This is inside spoke in terraform.tfvars. Names, private endpoints, Blob zone
registration, versioning, retention and diagnostics are wired automatically;
replication_type/delete_retention_days can be explicitly increased. The public
connectivity contract must publish the existing Blob zone. Each root supports
both convenience output IDs and actual zone-name/key maps. No storage is created
by default, so no unused account is introduced.

For existing VMs, optional spoke.backup takes recovery_vault_id, backup_policy_id
and virtual_machines (a map of existing VM ARM IDs). The backup policy and VMs
must be in this workload subscription and region-compatible. Select a policy
that meets the approved RPO/RTO, import pre-existing enrollments instead of
creating duplicates, and retain recovery points during any removal. Backup
vaults and compute remain owned by their existing deployment states.

Mixed-workload compute, databases, ingress/WAF and service-specific data backups
are intentionally separate application patterns. They consume spoke outputs;
none is universally appropriate to deploy in an empty landing zone. When approved
telemetry is enabled, set up the
application SDK/agents and managed-identity telemetry credential. Initial
telemetry endpoints are Entra-authenticated public HTTPS via hub egress, not
private-only AMPLS. A private-only mode requires the separately approved,
working central Azure Monitor Private Link path.

## Acceptance Evidence

See [TESTING.md](TESTING.md) for the completed local checks and remaining live
acceptance gates.
Use [ACCEPTANCE.md](ACCEPTANCE.md) to record read-only client-environment
connectivity checks without deploying or destroying the isolated test fixture.

Run init/validate/test in each workspace. Automatic tests are mocked; they do
not establish client-side deployment, licensing approval or live network access.
Use the blueprint integration-tests runbook for actual Azure evidence:

- Correct target subscription, environment, region-short names and tags.
- IPAM-approved non-overlapping addresses; NSG/UDR on every subnet.
- Both peering states Connected; private zone link and real hybrid DNS path.
- Approved egress/NVA routing and effective application NSG rules.
- Private-only, RBAC/purge-protected dedicated vault and approved PE connection.
- Central AuditEvent diagnostic setting without a policy-created duplicate.
- Managed-identity secret access from the actual workload network.
- Approved Defender/flow-log policy compliance and actual log ingestion.
- Stakeholder review/sign-off for the four tickets.

The isolated fixture validates route configuration without deploying a real
firewall/SD-WAN appliance. Actual inspected egress, hybrid routing, policy
convergence and client acceptance remain staging/client tests, not claims made
by a successful Terraform mock suite.
