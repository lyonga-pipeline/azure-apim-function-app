# Platform Network Peering Non-Production

PHASE 2: one platform-owned HCP workspace/state connects approved non-production VNets to the shared hub. Production uses its [own root](../platform-network-peering-prod/README.md). The unapplied np1/np2/np3 examples were consolidated here; no deployed state or legacy identity peering was moved.

**Status:** implementation and mock tests are complete; live adoption is not. The committed [terraform.tfvars](terraform.tfvars) contains documentation IDs/CIDRs and `enabled=false`. It currently creates no Azure resources. Publish/pin the verified pattern and naming dependency, supply approved values, configure external controls and complete a live pilot before rollout. The repository's relative module source is for development, not an approved registry release pin.

## What This Deploys

For **each entry** in `attachments`, the enabled workspace:

1. Cross-checks the reviewed inventory against versioned public HCP producer outputs and live VNet CIDRs; rejects mismatched tenant, environment, network identity, DNS intent, ownership or overlapping address ranges.
2. Creates **hub-to-spoke** peering under the existing hub VNet, then **spoke-to-hub** peering under the existing attached VNet. Both directions are always managed together, including across subscriptions.
3. Creates one DNS VNet link per `private_dns_zone_ids` entry, under that existing central zone, pointing at the attached VNet. Autoregistration is always off.

The committed examples declare `orders_dev`, `orders_test`, `orders_uat` and `orders_sandbox`, each with two zones. After replacing placeholders and enabling, that inventory requests **8 peerings and 8 DNS VNet links**, plus Terraform contract guards. It does not create every allowed environment automatically: only the declared VNet instances are attached.

**Not created or changed here:** subscriptions, VNets, subnets, NSGs, route tables/routes, gateways, Key Vaults, storage accounts, central DNS zones, private endpoints, endpoint DNS zone groups/records, DNS forwarders, application access roles or Palo Alto configuration. Their existing owners must supply them. A DNS link or peering is not proof of working DNS, firewall routing or application access.

## Workspace Inputs

Required means required for an enabled deployment unless stated otherwise. Optional means the schema has a default; it does not override enterprise approvals or a producer's declared requirements.

| Input | Requirement / Default | Value To Supply |
| --- | --- | --- |
| `tenant_id` | Required, including local disabled-root validation | Actual Entra tenant UUID; all target VNets/zones must belong to this tenant. |
| `execution_subscription_id` | Required | Provider context subscription UUID, normally the hub subscription. Full resource IDs select the actual hub/spoke/DNS targets; this does not grant permissions in them. |
| `enabled` | Optional; `false` | Set `true` only after adoption gates are satisfied. False skips the attachment module, not an operational pause for a live state. |
| `allowed_environments` | Optional; `["dev", "test", "uat", "sandbox"]` | Explicit reviewed producer labels. Nonempty lowercase slugs up to 32 characters; `prod`, `nonprod` and legacy `np1`/`np2`/`np3` are rejected in this new-LZ root. `sbx` is an explicitly approved alternative, not an automatic alias. |
| `hub` | Required when enabled; default `null` | Existing hub identity, CIDRs and its public producer workspace; fields below. |
| `attachments` | Optional; `{}` | Reviewed map of actual VNet instances. Empty means no attachments. Use stable keys such as `orders_dev`; removing/renaming a key is a lifecycle change. |
| `reserved_address_spaces` | Schema-optional; `[]`. Required operational IPAM evidence | Complete relevant IPv4 ranges outside this batch/hub: on-premises, partners, production and other networks. Exclude this batch's own ranges and the hub, which are checked separately. An empty/incomplete inventory cannot detect overlaps with omitted networks. |
| `deployment_controls` | Required when enabling; defaults fail adoption | Workspace-level approval and ownership/gate attestations; details below. |
| `allow_local_cli_auth` | Optional; `false` | Local Azure CLI authentication exception only. Keep false in HCP; mocks need no Azure login. |
| `tfc_azure_dynamic_credentials` | Runtime-injected for HCP OIDC; default `null` | HCP supplies credential file paths. Do not put tokens, passwords or credential contents in tfvars. |

`nonprod` is the fixed **state boundary** in `main.tf`, not a producer environment to pass in tfvars. Every attachment retains its real `dev`, `test`, `uat` or `sandbox` label. Single-tenant IPv4 is supported; cross-tenant/IPv6 attachments are outside this pattern.

Keep the attachment inventory and allowlist in reviewed Git tfvars; protect HCP variable changes so they cannot silently override that inventory. Root inputs are Terraform-category variables if entered in HCP; object/map/set values need HCL enabled. The `TFC_AZURE_*` settings below are environment-category variables. "Public outputs" means authorized reads of non-sensitive HCP outputs, not anonymous/public Internet access.

Use **`sandbox` as the canonical label** with the current workload-v2 blueprint, naming and tagging modules. The peering layer/generic-v3 producer can also accept `sbx` when explicitly allowlisted and published exactly by the actual VNet owner. Do not simply rename a v2 producer to `sbx`: its naming/tagging/blueprint validation must first support that label in an approved release. Do not attach both sandbox/sbx entries for the same VNet, normalize them in the consumer, or rename an existing-LZ VNet/state as part of this correction.

### Hub Object

| Field | Requirement / Default | Meaning |
| --- | --- | --- |
| `virtual_network_id` | Required | Full existing hub VNet ARM ID, not a subscription ID or peering ID. Must match the hub producer. |
| `address_space` | Required | Nonempty set of actual hub IPv4 CIDRs, matching both public outputs and the live VNet. This does not change its address space. |
| `organization`, `workspace` | Both required | HCP organization and the existing hub producer workspace, normally `Compeer-Financial-Services` / `platform-connectivity`. These are not Azure subscription names. |
| `contract_version` | Optional; `"0.1.0"` | Supported hub output schema. Not the Terraform CLI or registry module release version. |
| `gateway_ready` | Optional; `false` | Approval assertion used when requesting gateway transit. It does not discover, create or validate an actual gateway automatically. |

### Attachment Object

Repeat this object for each actual VNet. Multiple entries may belong to the same workload subscription; no per-subscription provider alias is needed.

| Field | Requirement / Default | Meaning / Example |
| --- | --- | --- |
| Map key, e.g. `orders_dev` | Required, stable | Terraform resource identity. Lowercase leading letter, then letters/digits/underscores/hyphens. Not an Azure resource name. |
| `spoke_virtual_network_id` | Required | Full existing attached VNet ARM ID. Platform VNets use the same field. No VNet is created/imported into attachment state. |
| `address_space` | Required | Nonempty actual IPv4 CIDRs matching the live VNet; v3 also checks producer CIDRs. An IPAM reference alone does not replace these values. |
| `producer.organization`, `producer.workspace` | Both required | Existing HCP VNet-owner workspace publishing the approved public attachment contract. Not this attachment workspace itself. |
| `producer.contract_version` | Optional; `"2.0.0"` | Existing workload blueprint v2, or generic platform/workload v3 (`"3.0.0"`). This selects an output schema, not a module package version. |
| `attachment_kind` | Optional; `"workload"` | `workload` for application VNets; `platform` requires v3 and matching producer classification. Does not create application/platform resources. |
| `environment` | Conditional; explicitly supplied in these examples | Actual producer environment, present in the root allowlist and equal to the producer output. V2 can derive it from `naming_context.environment`; grouped v3 entries must declare it. Never substitute `nonprod`. |
| `naming_context` | Required for v2; omit for v3 | `{ region, environment, domain, appcode }`, exactly matching the workload producer. Example: centralus / dev / internal-apps / orders. It is validation metadata, not an instruction to rename the VNet. |
| `approval_reference` | Required, nonempty | Network-approved change/ticket reference or URL, e.g. `NET-CHANGE-123`. Records authorization for this attachment's membership/settings. |
| `ipam_reference` | Required, nonempty | Real approved address reservation/reference or URL, e.g. `IPAM-RESERVATION-123`. Evidence for this VNet's CIDR allocation. |
| `allow_forwarded_traffic` | Optional; `true` | Sets forwarded-traffic permission on both halves for the approved hub NVA design. Does not create UDRs, firewall rules or guarantee inspection/return routing. |
| `gateway_transit` | Optional; `false` | True makes the hub offer transit and the spoke use its remote gateway. Requires matching producer intent, `hub.gateway_ready=true` and real gateway/inspection approval. Not required merely for Palo Alto forwarding. |
| `peering_names` | Optional; `null` | If provided, both `hub_to_spoke` and `spoke_to_hub` are required. Explicit Compeer names are supplied in tfvars; omission uses the existing naming helper, as explained below. |
| `private_dns_zone_ids` | Conditional; default `{}` | Existing central DNS zones to link to this VNet. Must exactly match producer keys/IDs. Details below. |
| `private_dns_link_names` | Optional; `{}` | Per-zone overrides for the DNS **link resource names**, not zone names or DNS records. Omitted keys use generated names; they do not omit links. |
| `tags` | Optional; `{}` | Applied only to the managed DNS VNet links. Not to the peerings, VNets or referenced services. Supply approved tag values where policy requires them. |

V2 producers publish `attachment_contract` plus context (directly or under `spoke`); v3 publishes `network_attachment_contract`. Both must identify `owner="central-attachment-workspace"` and agree with the approved hub/VNet/environment. Producer peering names must remain unset; v2 DNS intent must leave central link names unset and permit linking. This workspace supplies those names. Publishing output values does not transfer existing resource ownership.

## DNS Inputs And Ownership

### Zone IDs And Logical Keys

For the v2 workload contract used by the committed examples:

| Map Key | Existing Zone Referenced | What The Entry Does |
| --- | --- | --- |
| `key_vault` | `privatelink.vaultcore.azure.net` | Creates a resolution-only link from this zone to the attached VNet. **Does not create a Key Vault or its private endpoint.** |
| `storage_blob` | `privatelink.blob.core.windows.net` | Creates a resolution-only link for Blob private-endpoint DNS. **Does not create a storage account, blob container or private endpoint.** |

The keys are contract labels, not booleans, service names to deploy, or names of individual vaults/storage accounts. Supply the **zone ARM ID**, for example:

```text
/subscriptions/<dns-subscription-uuid>/resourceGroups/<dns-rg>/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net
```

Get it from the existing central zone owner/public outputs or its Azure resource properties. It is not a storage account ID, private endpoint ID, zone FQDN alone or DNS server IP. Reuse the central zones; this workspace does not create new copies. DNS zones may be in a different approved subscription from both hub and workload.

**Conditional does not mean freely removable:** `private_dns_zone_ids` must contain exactly the keys/IDs requested by the producer. With v2, these correspond to its `key_vault_private_dns_zone_id`, `storage_blob_private_dns_zone_id` and `private_dns_zones` intent. Dropping/adding a zone only in this consumer fails the contract. V3 can request other approved logical keys/zones, such as Azure Files, but consumer and producer must still agree exactly. Do not add `storage_file` to a v2 entry.

### Link Names

`private_dns_link_names` uses the same logical keys as `private_dns_zone_ids`. It may supply a subset of overrides, but cannot contain keys without a corresponding zone ID. By default, every requested link is named `<lowercase-attached-vnet-name>-link`.

For example, these two names can be identical because they live in different zones:

```hcl
private_dns_link_names = {
  key_vault    = "workload-cus-dev-int-orders-vnet-link"
  storage_blob = "workload-cus-dev-int-orders-vnet-link"
}
```

Names must be unique within each zone, not globally. There can be only one link for a given VNet/zone pair. A matching name does **not** automatically reuse/import an existing link. If another state owns that link, arrange a reviewed ownership handoff/import before managing it here; never create a second owner. [Microsoft: private DNS VNet links](https://learn.microsoft.com/en-us/azure/dns/private-dns-virtual-network-links).

### Common DNS Variants

These are **fields inside one attachment**, not complete standalone tfvars files. Change producer intent and obtain approval first; do not disable required audit/security or DNS controls merely to make a plan pass.

| Desired Variant | `private_dns_zone_ids` | `private_dns_link_names` | Prerequisite |
| --- | --- | --- | --- |
| Vault and Blob, explicit names | Both existing zone IDs, as committed | Both overrides, as committed | Producer requests those exact two zones. |
| Same zones, generated link names | Keep both IDs | Omit the field or use `{}` | Same producer intent; two links still created. |
| Vault only | Only `key_vault = "<existing-vault-zone-ARM-ID>"` | Omit/`{}`, or only the `key_vault` override | Producer requests only the vault zone; no leftover Blob override. |
| No attachment-owned DNS links | Omit/`{}` | Omit/`{}` | Producer requests no such links and the network team approves a working DNS path. Both peerings are still created. |

DNS links do not create private-endpoint records: endpoint DNS zone groups/records stay with the workload/private-endpoint owner. Autoregistration off prevents VM hostname registration into these service zones. Custom/AD DNS forwarding must already be configured for Compeer's actual resolution path; peering alone or these links alone do not configure DNS forwarders. [Microsoft: private endpoint DNS integration](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns-integration).

## Peering Names And Flags

The committed naming convention follows the identity/hub model without taking over its existing peerings:

```hcl
peering_names = {
  spoke_to_hub = "peer-workload-cus-dev-int-orders-vnet-to-hub"
  hub_to_spoke = "peer-hub-to-workload-cus-dev-int-orders-vnet"
}
allow_forwarded_traffic = true
gateway_transit         = false
```

Keep explicit names to follow this convention. If `peering_names` is omitted, the backward-compatible helper uses `<hub-vnet-name>-to-<spoke-vnet-name>` and the reverse, **not** the `peer-...-to-hub` shorthand. There is no single-direction opt-out. Virtual-network access is always enabled on both halves. The hub never uses the spoke's gateway; the spoke never offers gateway transit back to the hub.

Explicit peering/link names follow the pattern's 2-80 character validation. Preserve exact live names when importing: changing a resource name can replace it. Changing `gateway_transit` also requires matching producer intent, not just a local boolean change.

## Approvals And Authentication

`deployment_controls` records the **workspace-level** adoption decision:

- `approval_reference`: nonempty approved change/reference covering adoption of this state.
- `exclusive_ownership_verified=true`: confirm no other active backend owns these peering/link resources, or that the approved handoff is complete.
- `shared_hub_gate_configured=true`: attest the actual protected shared-hub deployment gate and HCP bypass restrictions are configured.

The per-attachment `approval_reference` covers each approved attachment; `ipam_reference` identifies its approved address reservation. A single reviewed change may cover multiple entries. Terraform checks references are nonempty; it **does not** validate ticket status, obtain approval, contact IPAM, reserve addresses, create an exclusive gate or grant RBAC. The strings and booleans are evidence pointers/attestations, not substitutes for those controls.

Configure HCP environment variables `TFC_AZURE_PROVIDER_AUTH=true`, `TFC_AZURE_PLAN_CLIENT_ID` and `TFC_AZURE_APPLY_CLIENT_ID` with approved non-production principals and exact federation subjects. HCP injects `tfc_azure_dynamic_credentials`; keep `allow_local_cli_auth=false`. The TFE provider separately needs approved read access to the producers' public outputs; Azure OIDC does not grant HCP output access.

Platform authorization/onboarding must supply scoped peering read/write/delete and required peer/join rights on approved VNets, and DNS-link lifecycle/join rights on approved central zones. The pattern skips provider registration, so registration readiness belongs to the platform owner. Do not grant Owner/Network Contributor across subscriptions merely for peering. See the [permission matrix and gate runbook](../../network-attachments/README.md). Hub-scoped peering rights can still affect other peerings on that shared hub; state separation does not eliminate that risk.

## Deployment And Lifecycle

1. Keep only the actual, approved VNet entries; replace all documentation UUIDs, CIDRs, producer workspace names, change/IPAM references and tag values. Confirm producer contracts exist and DNS intent matches exactly.
2. Publish/pin the verified pattern and naming dependency. Configure HCP workspace `platform-network-peering-nonprod` to this root, with its own backend, trigger path, release pin and plan/apply identities. Use Terraform `>=1.11.4,<2.0.0`; this root pins AzAPI `2.4.0` and TFE `0.82.0`.
3. Complete IPAM, scoped RBAC/OIDC, public-output access, shared-hub gate and exclusive-owner review. Coordinate required hub/spoke routes, NSGs, DNS forwarding and Palo Alto changes with their owners. All non-production entries share this state's permissions, release, plan/recovery scope and approval lifecycle.
4. Set the real adoption attestations, then `enabled=true`. Review the **full inventory plan**, including imports for any approved existing children. Apply under the common hub gate, also used by production, core connectivity and legacy writers. No VNet, route or DNS zone moves into this state.
5. Accept only after both peerings are Connected/Succeeded and live DNS/private-endpoint resolution, approved inspected flows, symmetric return paths and blocked flows are verified. Preserve state/re-plan after partial failure; the reciprocal pair is not atomic.

**Never set `enabled=false` to pause an applied state:** it proposes deletion of its attachment module. Stop/lock runs operationally. Do not run dev/test/uat/sandbox subsets against this same backend via runtime tfvars: omitted keys propose teardown. Removing entries or changing stable keys/VNet IDs/names needs a reviewed lifecycle plan. Existing identity/single-pair ownership remains unchanged. If any old np workspace was applied externally, follow the [state handoff runbook](../../network-attachments/README.md#existing-state-handoff), not a directory/backend rename.

## Outputs

| Output | Meaning |
| --- | --- |
| `environment` | Fixed state label `nonprod`. |
| `allowed_environments` | Approved actual producer environment labels. |
| `contract_version` | Consumer output schema `1.0.0`, independent of module release versions. |
| `attachments` | Map keyed like the inventory: both child IDs, resolved peering names, actual producer environment, VNet references, observed peering states and owned DNS link IDs. Empty while disabled. |

The first-created peering's observed state may need a refresh; output state alone is not end-to-end acceptance.

## Verification

```bash
# From this root; private module/provider downloads may require registry/network access.
terraform init -backend=false
terraform validate
terraform test
```

Tests cover disabled populated inventory, adoption/allowlist guards and mock application of the actual committed tfvars, including both peering names and exact DNS links. The full [attachment regression suite](../../network-attachments/test.sh) additionally covers v2/v3 contracts, IPAM, DNS variants, legacy compatibility and operating controls. Mocks do not deploy Azure resources or prove live permissions, DNS, routing, concurrency enforcement or application availability.

See the [batch pattern input reference](../../../../patterns/terraform-azapi-compeer-network-attachments/README.md) and [peering standard](../../PEERING-STANDARD.md) for the wider ownership/release model.
