# platform-identity-external

## PHASE 2 Implementation

Dedicated external-forest infrastructure and backup owner. Legacy directory-services contains external DC entries: verify actual ownership before enabling this separate root.

This is a canonical owner-aligned root, not a phase-selected workspace. See [engineering handoff](../../../phase2/ENGINEERING-HANDOFF.md) for the exact file/ownership map and release dependencies.

- `terraform.tfvars.example` is inert reference configuration; it is not auto-loaded.
- Where present, `approved-pilot.tfvars.example` exercises enabled capabilities with synthetic inputs, not production approvals.
- Use a separate HCP workspace/state, scoped run identity, main-branch working directory and trigger path. Instantiate another root for independently promoted subscriptions/environments.
- Sources are local catalog paths for integration testing. Publish and pin approved registry releases before actual deployment. Do not select environment or module version through runtime tfvars.
- Existing resources stay in their current states. These new Phase 2 roots have not been applied; no state migration is automated here.

No new ARM resource locks or Phase 3 resources are introduced. Read [live acceptance](../../../phase2/RUNBOOKS.md) before enabling a capability.

## Central Attachment Handoff

Set the optional `central_attachment` object in the identity root's tfvars to publish the public `network_attachment_contract` v3.0.0. It contains the authenticated tenant context, actual VNet ID/CIDRs, `platform` classification, `prod` environment, approved hub and exact private DNS intent. The configured tenant/subscription must match the provider context. `gateway_transit` stays off.

- `central_attachment = null` preserves existing callers and the older `central_attachment_inputs` output. The new output is null until both this input and the identity root are enabled.
- `central_attachment.private_dns_zone_ids = {}` means no private DNS VNet links. AD DNS forwarding and DC promotion are separate workflows. Supply zone IDs only when this VNet needs those approved private-link zones.
- Publishing metadata creates no peerings or DNS links and transfers no VNet ownership. The production attachment workspace owns both peering directions; this root retains its VNet, subnets, UDRs, controllers and backups.

After the identity foundation is applied and its public output is available, **merge** an entry like this into the complete reviewed `attachments` map in [platform-network-peering-prod](../platform-network-peering-prod/README.md). Do not replace the existing map or run a partial inventory against its backend; omitted entries propose deletion. All values below are documentation placeholders.

```hcl
external_identity_prod = {
  attachment_kind          = "platform"
  environment              = "prod"
  spoke_virtual_network_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-cus-prod-ext-dc-rg/providers/Microsoft.Network/virtualNetworks/identity-cus-prod-ext-dc-vnet"
  address_space            = ["10.210.0.0/24"]
  producer = {
    organization     = "Compeer-Financial-Services"
    workspace        = "platform-identity-external"
    contract_version = "3.0.0"
  }
  approval_reference      = "REPLACE_WITH_APPROVED_CHANGE"
  ipam_reference          = "REPLACE_WITH_APPROVED_IPAM_RESERVATION"
  gateway_transit         = false
  allow_forwarded_traffic = true
  peering_names = {
    hub_to_spoke = "peer-hub-to-identity-cus-prod-ext-dc-vnet"
    spoke_to_hub = "peer-identity-cus-prod-ext-dc-vnet-to-hub"
  }
  private_dns_zone_ids = {} # Must exactly match the identity producer's intent.
}
```

The reviewed inventory remains authoritative: do not automatically add entries from producer outputs. Match the actual tenant, hub, VNet, CIDRs, environment and DNS intent; configure scoped OIDC/RBAC, output-read access and the common-hub gate before enabling attachment. Existing legacy pairs require a separate approved state handoff.

Release dependencies: publish/pin the directory-services pattern with the additive `identity_vnet_address_space` output and the attachment package's output-only `producer` submodule. No separate naming-module release is needed. The cross-root regression runs the real identity and production attachment roots with mocked Azure/HCP providers, checking exact HCP payload parity with the real producer output; it is not live network acceptance.
