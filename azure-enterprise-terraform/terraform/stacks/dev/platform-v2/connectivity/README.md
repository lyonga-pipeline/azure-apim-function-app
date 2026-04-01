# Dev Platform V2 Connectivity

## Purpose

This stack is the shared network foundation for the `dev` platform plane.

It creates the hub VNet, the hub subnets, and the shared Private DNS zones
that downstream platform and workload stacks consume.

For the broader platform design, see `terraform/README-v2.md`.

## What This Stack Owns

- the connectivity resource group
- the hub VNet
- the hub subnets
- the shared Private DNS zones
- the hub VNet links to those Private DNS zones

## What This Stack Reads From

- direct environment inputs such as names, address spaces, and location
- optional `global/subscriptions` remote state for subscription validation

This stack does not depend on identity, management, or workload state.

## Module Composition

The stack itself is intentionally thin. Most of the network behavior is pushed
into shared child modules.

1. `module "resource_group"`
   Creates the connectivity resource group.
2. `module "hub_network"`
   Calls `modules/vnet-hub` to build the hub VNet and its subnet layout.
3. `modules/vnet-hub`
   Decides which subnets to create, applies the default subnet CIDRs when no
   custom subnet map is supplied, and optionally deploys Azure Firewall.
4. `modules/vnet-hub -> module "network"`
   Calls the generic `modules/network` module to create the VNet, subnets,
   NSGs, NSG rules, subnet associations, route table associations, and NAT
   gateway associations.
5. `module "private_dns"`
   Creates the shared Private DNS zones and links the hub VNet to every zone.

That means this stack forms the hub by combining:

- a resource group
- a hub VNet with a predefined subnet layout
- optional hub firewall resources
- shared Private DNS zones linked to the hub VNet

## Current Dev Deployment Shape

The checked-in `dev.tfvars` currently deploys:

- resource group `rg-dev-connectivity`
- hub VNet `vnet-dev-hub`
- hub VNet CIDR `10.0.0.0/16`
- Azure region `eastus2`
- Azure Firewall disabled

## Default Hub Subnet Layout

This stack does not pass a custom `subnets` map into `modules/vnet-hub`, so the
module uses its built-in default hub layout.

By default, the hub creates **6 subnets**:

| Subnet | Default CIDR | Purpose |
| --- | --- | --- |
| `AzureFirewallSubnet` | `10.0.0.0/26` | Reserved for Azure Firewall when enabled |
| `AzureBastionSubnet` | `10.0.0.64/26` | Reserved for Azure Bastion if added later |
| `shared-services` | `10.0.1.0/24` | Shared platform services hosted in the hub |
| `private-endpoints` | `10.0.2.0/24` | Private Endpoint subnet |
| `dns-inbound` | `10.0.3.0/24` | Reserved for DNS inbound resolver services |
| `dns-outbound` | `10.0.4.0/24` | Reserved for DNS outbound resolver services |

Important detail:

- the hub VNet CIDR comes from the stack input `hub_address_space`
- the subnet CIDRs come from defaults inside `modules/vnet-hub`
- if a custom `subnets` map is later supplied to `modules/vnet-hub`, it
  replaces the default 6-subnet layout entirely

## How CIDRs Are Set

The address ranges are set in two layers:

1. Stack-level VNet CIDR
   `hub_address_space` is passed from this stack into `modules/vnet-hub`, then
   into `modules/network`, and becomes the VNet `address_space`.
2. Module-level subnet CIDRs
   `modules/vnet-hub` supplies default subnet CIDRs for the six hub subnets
   unless a custom subnet map is provided.

In the current `dev` example:

- VNet CIDR: `10.0.0.0/16`
- default subnets are carved from that space using the fixed defaults above

## NSG Behavior

NSGs are created by the generic `modules/network` module, not directly by the
stack root.

The behavior is:

- an NSG is created only for subnets that have one or more `nsg_rules`
- an NSG association is created only for those same subnets
- the default hub module only wires NSG rules into `shared-services` through
  `shared_services_nsg_rules`

What that means for this stack today:

- the stack does not pass any `shared_services_nsg_rules`
- the stack does not pass a custom `subnets` map with `nsg_rules`
- therefore the current checked-in `dev` hub creates **0 NSGs**
- therefore the current checked-in `dev` hub also creates **0 NSG
  associations**

So the subnet layout exists today, but the default sample does not yet attach
NSGs to those subnets.

## Other Subnet-Level Features Supported By The Child Modules

The generic `modules/network` module can also attach optional subnet settings
when they are provided through `modules/vnet-hub`:

- service endpoints
- route tables
- NAT gateways
- subnet delegations
- private endpoint policy settings

This stack does not currently pass any of those optional settings except for
the private endpoint policy behavior on the `private-endpoints` subnet.

## Private Endpoint Subnet Behavior

The `private-endpoints` subnet is created with private endpoint network
policies disabled.

That is intentional. It makes the subnet suitable for Azure Private Endpoints
used by workload and platform services.

## Firewall, Bastion, And DNS Resolver Behavior

The subnet layout reserves space for several common hub services, but this
stack does not deploy all of them by default.

Current behavior:

- `AzureFirewallSubnet` is always created as part of the default layout
- Azure Firewall and its public IP are created only when `enable_firewall = true`
- the current `dev.tfvars` sets `enable_firewall = false`
- `AzureBastionSubnet` is created, but no Bastion resource is created here
- `dns-inbound` and `dns-outbound` subnets are created, but no DNS Private
  Resolver resources are created here

So this stack currently creates the **hub-ready network shape**, while some of
the shared services that could live in that shape are still optional or future
additions.

## Private DNS Zones

This stack also creates centrally managed Private DNS zones through
`modules/private-dns`.

By default it creates **9 Private DNS zones**:

- `privatelink.vaultcore.azure.net`
- `privatelink.blob.core.windows.net`
- `privatelink.queue.core.windows.net`
- `privatelink.table.core.windows.net`
- `privatelink.file.core.windows.net`
- `privatelink.azurewebsites.net`
- `privatelink.database.windows.net`
- `privatelink.servicebus.windows.net`
- `privatelink.azconfig.io`

The module then links the hub VNet to every zone. With the current defaults,
that produces:

- 9 Private DNS zones
- 9 hub VNet links

This is what lets other stacks consume the shared hub DNS plane for Private
Endpoints.

## How The Pieces Work Together To Form The Hub

The hub is formed in this order:

1. the stack creates the connectivity resource group
2. the stack calls `modules/vnet-hub`
3. `modules/vnet-hub` selects the default 6-subnet hub layout
4. `modules/vnet-hub` calls `modules/network`
5. `modules/network` creates the VNet and all six subnets
6. `modules/network` creates NSGs only if subnet rules were supplied
7. `modules/vnet-hub` optionally adds Azure Firewall on the reserved firewall
   subnet
8. the stack calls `modules/private-dns`
9. `modules/private-dns` creates the shared Private DNS zones and links the
   hub VNet to them

That combination gives you:

- a hub VNet
- a hub subnet plan for shared services and future expansion
- optional hub security controls such as subnet NSGs and firewall
- a centralized Private DNS layer for Private Endpoint resolution

## Outputs Other Stacks Use

This stack publishes the shared network facts that other stacks consume:

- `hub_vnet_id`
- `hub_vnet_name`
- `hub_subnet_ids`
- `firewall_private_ip`
- `private_dns_zone_ids`
- `private_dns_zone_names`

Downstream stacks use these outputs for peering, DNS linking, and private
endpoint integration.

## Subscription Catalog Mapping

This sample stack should use the `connectivity` entry in `global/subscriptions`.

That means:

- `subscription_catalog_entry_key = "connectivity"`
- `subscription_id` should match the real connectivity subscription recorded in
  the central catalog

Why this matters:

- the connectivity stack is a shared platform service
- it should validate against the connectivity platform subscription
- it keeps the stack aligned with the stronger enterprise pattern of one
  subscription per major platform function

## Practical Notes

- this is the correct root for shared hub networking and shared Private DNS
- spoke-local networking should stay out of this stack
- if you later add Firewall, Bastion, DNS Private Resolver, or routing assets,
  this is the natural place to add them when they are shared platform services
- if you expect workloads to enforce subnet isolation through NSGs, you need to
  explicitly pass NSG rules into the hub module because the current sample does
  not create any NSGs by default
