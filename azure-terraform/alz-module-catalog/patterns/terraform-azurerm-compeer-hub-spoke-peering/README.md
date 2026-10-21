# Hub-To-Spoke Peering Pattern

NET-22 / Step 11.4 / ticket 204115. Pure Azure composition: one hub-to-spoke
peering, one spoke-to-hub peering and OPTIONAL existing-zone VNet links. No
HCP provider, remote state, token, VNet, DNS zone, gateway or firewall is created.
The implementation is consumed by the platform-owned network-peering HCP
adapter and the isolated test fixture, not the spoke blueprint. Do not duplicate
the two peering resources elsewhere.

## Code Reuse Versus State Ownership

Compeer's selected model is a separately privileged central attachment state
owning BOTH peering directions and the required DNS links. Spoke provisioning
publishes intent only and has no hub provider or peering/link modules.
The central state consumes the versioned contract after the spoke apply.
Central means platform-owned, not necessarily one shared state for every spoke.
Moving an existing attachment between states requires a reviewed non-destructive
handoff, not toggling a flag. See
[ATTACHMENT.md](../../implementations/workload-lz/ATTACHMENT.md).

The existing platform-network-peering workspace is an HCP-output-reading adapter
for that central-state model; the Azure implementation remains this pattern.

## Composition

```hcl
module "peering" {
  source = "../terraform-azurerm-compeer-hub-spoke-peering"
  providers = {
    azurerm.hub   = azurerm.connectivity
    azurerm.spoke = azurerm
    azurerm.dns   = azurerm.dns
  }
  hub_subscription_id   = var.hub_subscription_id
  spoke_subscription_id = var.spoke_subscription_id
  hub_virtual_network_id   = var.hub_virtual_network_id
  spoke_virtual_network_id = var.spoke_virtual_network_id
  peering_names = {
    hub_to_spoke = module.naming.vnet_peering_names["hub"]
    spoke_to_hub = module.naming.vnet_peering_names["spoke"]
  }
  private_dns_zones = var.approved_private_dns_zones # From the spoke contract.
}
```

The caller supplies all three provider aliases. DNS can be in a different
subscription from the hub. For a central attachment root, supply the actual
private_dns_subscription_id and private_dns_zones entries with existing names,
actual RGs and optional stable link_name values. No DNS auto-registration is
allowed in Private Link service zones. Scope privileges to the approved VNets
and zones rather than granting subscription-wide Owner.

Approved VNet IDs must be distinct and match the provider subscriptions/tenant.
Names and resource groups are derived from those IDs, avoiding inconsistent
duplicate identifiers. Forwarded traffic defaults on; gateway transit defaults
off. When explicitly approved, enable hub allow_gateway_transit and spoke
use_remote_gateways together. The dependency graph creates hub permission first.
Changing an established gateway-transit configuration still needs a reviewed
network change plan; pairing flags does not make Azure updates transactional.

This pattern does not create UDRs, enable NVA IP forwarding, exchange BGP routes,
install firewall rules or establish DNS forwarding. Those remain their existing
owners. Connected peerings alone do not prove shared-service or on-prem access.

## Tests And Acceptance

Run terraform init and terraform test. The suite mocks Azure but composes the
real base modules, checking reciprocal wiring, names, subscription guards,
gateway pairing, correct DNS ownership and Private Link registration settings.
The spoke's opt-in Azure integration fixture checks both live peerings Connected
and observed PE/DNS wiring. Actual hybrid routing, route symmetry, NVA rules,
DNS forwarding and representative shared-service probes still require Step 12
client validation. No live Azure acceptance is implied by the mock suite.

Architecture basis:
- https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/subscription-vending
- https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/hub-spoke-network-topology

The choice of Terraform state boundaries above is an engineering recommendation
for these ownership constraints, not a Microsoft mandate for a particular number
of workspaces.
