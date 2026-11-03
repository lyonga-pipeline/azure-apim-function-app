# Spoke DNS Ownership

## Select An Owner

The default described below remains Terraform-owned registration. The opt-in
[Policy-owned mode](POLICY-DNS.md) removes spoke zone inputs and documents platform
rollout, permissions, state handoff and the required live readiness gate.

## Deployment Boundary

Spokes use one workload AzureRM provider. They create private vault/Blob endpoints
and their DNS zone groups, not central DNS zones or VNet links. No DNS provider,
DNS execution subscription or legacy Terraform workspace/state access is needed.
The workload identity still needs approved linked-resource authorization on the
actual existing zones. Full IDs identify resources; they do not grant access.

| Component | Owner |
| --- | --- |
| Existing Azure Private DNS zone, including a manually created zone | Existing platform/DNS owner; no import or change of ownership |
| Workload private endpoint and its `privateDnsZoneGroup` child | This workload state; zone-group creation registers endpoint records in the existing zone |
| DNS servers, conditional forwarding and resolver VNet zone links | Existing network/identity/DNS owner |
| Both hub peerings and approved spoke-to-zone VNet links | Central attachment state; unchanged by this release |

A zone group is not a zone and is not a VNet link. Creating a private endpoint
alone is not proof of DNS registration, forwarding or connectivity. Central DNS
resolution does not remove the endpoint-record requirement. Do not create new
zones merely because the new LZ has none, and do not assume hub peering makes
DNS resolution or spoke-to-identity connectivity transitive.

## Supply Existing Zone References

For prod/nonprod internal-app roots, configure a shared, network-approved HCP
variable set restricted to its intended workspaces:

| HCP setting | Value |
| --- | --- |
| Variable name | `private_dns_zone_ids` |
| Category | Terraform |
| HCL | Enabled |
| Sensitive | No; resource IDs are not credentials |

Example value, with actual existing IDs replacing every placeholder:

```hcl
{
  key_vault    = "/subscriptions/REPLACE-UUID/resourceGroups/REPLACE-RG/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  storage_blob = "/subscriptions/REPLACE-UUID/resourceGroups/REPLACE-RG/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
}
```

Alternatively set `private_dns_zone_ids = { ... }` at the top level of this
application/environment root's tfvars. The input takes precedence over the
existing `platform_inputs` zone fields, then optional connectivity outputs.
Configure only the required keys. KV and Blob zones may be in different approved
subscriptions accessible to the same deployment identity.

No change to old-LZ code or outputs is required. This is an approved reference
catalog, not resource discovery or ownership transfer. Other standalone callers
pass the same IDs through `platform.key_vault_private_dns_zone_id` and
`platform.storage_blob_private_dns_zone_id`. Their whole platform object still
needs the existing LAW, hub, DNS-server and governance metadata. To avoid HCP
output consumption entirely, the internal-app roots retain `use_tfe_outputs=false`
with complete approved `platform_inputs`; this does not remove real platform
dependencies such as central logging or inspected routing.

## Upgrade And Verification

Select the updated blueprint release and caller together. Remove the DNS alias
and module mapping; keep the workload provider plus root `tfe`/`time` providers
where used. Existing `private_dns_subscription_id` and
`connectivity_subscription_id` inputs are accepted but ignored for compatibility.
Do not remove aliases used by unrelated legacy peering/link resources.

Managed resource addresses and DNS zone-group names remain unchanged. Review a
real-state plan for no unintended replacement/deletion and verify the deployment
identity's permissions before applying. For enabled vault/storage, missing or
wrong zone IDs still fail; do not bypass this by changing the resource to public.

After apply, confirm endpoint approval/private IP, zone-group destination and A
records, then resolve the service hostname from the actual spoke client and test
private connectivity. Central forwarding must be configured and reachable.
Mock tests verify configuration, not Azure permission or DNS behavior.

Policy registration is an explicit alternate mode, never a fallback when zone
IDs are missing. It requires an approved platform rollout and does not
automatically transfer existing groups.

## Microsoft Guidance

- [Private endpoint DNS integration and zone-group lifecycle](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns-integration#private-dns-zone-group).
- [Platform-owned DNS registration through Azure Policy](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale), an alternative requiring its own tested permissions, assignments and ownership handoff.
