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
   custom subnet map is supplied, and optionally deploys Azure Firewall, NAT
   Gateway, and Azure Bastion.
4. `modules/vnet-hub -> module "network"`
   Calls the generic `modules/network` module to create the VNet, subnets,
   NSGs, NSG rules, subnet associations, route table associations, and NAT
   gateway associations.
5. `module "private_dns"`
   Creates the shared Private DNS zones and links the hub VNet to every zone.

That means this stack forms the hub by combining:

- a resource group
- a hub VNet with a predefined subnet layout
- optional hub firewall, NAT, and Bastion resources
- shared Private DNS zones linked to the hub VNet

## How Typical This Is For Enterprise Azure

Yes, this is a **typical starting pattern** for an enterprise Azure hub in a
landing zone architecture.

What is typical about it:

- the hub lives in a dedicated connectivity stack and subscription boundary
- shared network services are centralized in the hub instead of duplicated in
  workload subscriptions
- Private DNS zones for Private Link-enabled services are centralized
- the subnet layout reserves space for common shared services like Firewall,
  Bastion, and DNS
- Azure Firewall is treated as a shared hub capability rather than a
  workload-local component
- Firewall Policy is used to centralize firewall rule management instead of
  relying only on classic per-firewall rule collections

That aligns well with Microsoft guidance that connectivity subscriptions host
shared networking resources like hub networking, Azure Firewall, and Azure
Private DNS zones.

What is still simplified in this repo:

- no route tables currently force spoke egress or east-west traffic through the
  firewall
- no DNS proxy configuration exists yet
- no DNS Private Resolver is deployed yet for on-premises or custom DNS
  forwarding
- no VPN gateway or ExpressRoute gateway is deployed yet
- no DDoS plan is attached yet
- no multi-region hub pattern is modeled yet

So the current stack is a good **hub baseline**, but not yet a full
enterprise-grade secured transit hub by itself.

## Current Dev Deployment Shape

The checked-in `dev.tfvars` currently deploys:

- resource group `rg-dev-connectivity`
- hub VNet `vnet-dev-hub`
- hub VNet CIDR `10.0.0.0/16`
- Azure region `eastus2`
- Azure Firewall enabled
- Azure Firewall Policy attached to the hub firewall
- one baseline firewall network rule collection
- NAT Gateway enabled and attached to `AzureFirewallSubnet`
- Azure Bastion enabled on `AzureBastionSubnet`

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

## Where To Override Or Add Custom CIDRs

There are two different answers depending on whether you want to change the VNet
CIDR or the subnet CIDRs.

### Override The Hub VNet CIDR

This is already exposed at the stack root.

Change it in:

- `terraform/stacks/dev/platform-v2/connectivity/dev.tfvars`

using:

- `hub_address_space`

That value is passed from the stack root into `module "hub_network"` and then
into `modules/network` as the VNet `address_space`.

### Override The Hub Subnet CIDRs

This is **not currently exposed** by the connectivity stack root.

Right now, subnet CIDRs come from defaults inside `modules/vnet-hub`:

- `firewall_subnet_cidr`
- `bastion_subnet_cidr`
- `shared_services_subnet_cidr`
- `private_endpoints_subnet_cidr`
- `dns_inbound_subnet_cidr`
- `dns_outbound_subnet_cidr`

If you want to change those values without editing the child module defaults,
the recommended approach is:

1. add matching input variables to
   `terraform/stacks/dev/platform-v2/connectivity/variables.tf`
2. pass those variables into `module "hub_network"` in
   `terraform/stacks/dev/platform-v2/connectivity/main.tf`
3. set the environment-specific values in `dev.tfvars`

### Replace The Entire Default Hub Subnet Layout

If you need more than just CIDR changes, for example:

- extra subnets
- different subnet names
- route-table associations
- NAT gateway associations
- per-subnet NSG rules
- subnet delegations

then the better pattern is to expose and pass a full custom `subnets` map from
the connectivity stack root into `modules/vnet-hub`.

When a non-empty `subnets` map is supplied to `modules/vnet-hub`, it replaces
the default 6-subnet layout entirely.

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

## How To Add Custom NSG Rules

There are two levels of customization available in the child modules, but only
one of them is currently practical from this stack without code changes.

### Shared-Services Subnet Rules

`modules/vnet-hub` supports `shared_services_nsg_rules`.

That is the simplest way to attach an NSG to the `shared-services` subnet.

To make that configurable from this stack, the recommended change is:

1. add a `shared_services_nsg_rules` variable to
   `terraform/stacks/dev/platform-v2/connectivity/variables.tf`
2. pass it into `module "hub_network"` in
   `terraform/stacks/dev/platform-v2/connectivity/main.tf`
3. define the rules in `dev.tfvars`

The rule objects need values like:

- `name`
- `priority`
- `direction`
- `access`
- `protocol`
- optional source and destination port and address fields

### NSG Rules For Any Hub Subnet

If you need NSGs on subnets other than `shared-services`, then exposing
`shared_services_nsg_rules` is not enough.

In that case, expose and pass a full `subnets` map from the stack root into
`modules/vnet-hub`, because the generic `modules/network` module creates NSGs
for any subnet that has non-empty `nsg_rules`.

Practical recommendation:

- use `shared_services_nsg_rules` when you only need rules on
  `shared-services`
- use a full custom `subnets` map when you need per-subnet NSGs across the hub

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
- Azure Firewall, its public IP, and its attached Firewall Policy are created
  only when `enable_firewall = true`
- firewall policy rule collection groups are created only when
  `firewall_network_rule_collections` is non-empty
- the current `dev.tfvars` enables the firewall and adds a baseline
  `spoke-to-internet` policy-based network rule collection for outbound web
  traffic
- NAT Gateway can optionally be created with its own Standard public IP and
  attached to selected hub subnets
- the current `dev.tfvars` enables the NAT Gateway and attaches it to
  `AzureFirewallSubnet`
- `AzureBastionSubnet` is always created as part of the default layout
- Azure Bastion is created only when `enable_bastion = true`
- the current `dev.tfvars` enables Azure Bastion on `AzureBastionSubnet`
- `dns-inbound` and `dns-outbound` subnets are created, but no DNS Private
  Resolver resources are created here

So this stack currently creates the **hub-ready network shape**, while some of
the shared services that could live in that shape are still optional or future
additions.

## Why Private DNS, Public IP, And Firewall Matter

These are some of the most important moving parts in a hub-based Azure network.

### Private DNS

Private DNS zones are what make Private Endpoints usable by name instead of by
raw IP address.

Why they matter:

- workloads can keep using the normal service FQDNs
- DNS resolves those names to private endpoint IPs instead of public endpoints
- private endpoint records can be managed centrally in the connectivity layer
- workloads in different subscriptions can share the same central DNS plane

In this repo, the connectivity stack creates the zones, and workload stacks
link their spoke VNets to those same shared zones.

### Public IP

The public IP resources in this stack back Azure Firewall, Azure Bastion, and
optionally the NAT Gateway.

Why it matters:

- Azure Firewall uses a public IP for internet egress and DNAT scenarios in the
  standard hub pattern
- Azure Bastion uses a public IP to provide browser-based or native-client
  administrative access without exposing workload VMs directly
- NAT Gateway uses a public IP to provide stable and scalable outbound SNAT
  when that pattern is needed
- it gives the hub a controlled and auditable outbound public address
- it becomes one of the important public edge assets that should be protected,
  monitored, and often DDoS-covered

Important nuance:

- in this repo, the firewall public IP is created only when `enable_firewall`
  is `true`
- the Bastion public IP is created only when `enable_bastion` is `true`
- the NAT Gateway public IP is created only when `enable_nat_gateway` and
  `nat_gateway_create_public_ip` are both `true`

### Firewall

Azure Firewall is the central network security boundary in many enterprise hub
designs.

Why it matters:

- it can centralize outbound filtering
- it can inspect and control spoke-to-spoke or north-south traffic when routing
  is designed for it
- it is the common place to apply egress policy, FQDN filtering, DNAT, and
  network rule control
- Firewall Policy makes that rule model easier to standardize, reuse, and grow
  than classic direct firewall rule collections

Important nuance for this repo:

- enabling the firewall here creates the firewall, its public IP, and an
  attached Firewall Policy
- it does **not** by itself force traffic through the firewall
- to make the firewall operational as the transit security control, you still
  need route tables, firewall policy/rules, and usually DNS alignment

So the firewall in this stack is a **foundational hub component**, but not a
complete secured-routing implementation yet.

### Bastion

Azure Bastion is a common hub-hosted administrative access service.

Why it matters:

- it lets operators reach private VMs over TLS from the Azure portal or native
  client without giving those VMs public IPs
- it fits naturally in the hub because it is a shared management-plane service
- it reduces the pressure to expose jump hosts or management VMs directly to
  the internet

Important nuance for this repo:

- Bastion is now exposed as a first-class optional hub feature
- the current `dev.tfvars` enables it
- Bastion is useful when you want shared secure admin access, but it is not
  required for every landing zone

### NAT Gateway

NAT Gateway is optional and not universally required in a hub design, but it is
useful when you need predictable or higher-scale outbound SNAT.

Why it matters:

- it provides stable outbound public IPs
- it increases available SNAT ports compared with relying only on a single
  firewall public IP
- it can complement a firewall design when outbound scale is a concern

Important nuance for this repo:

- the current implementation can create a NAT Gateway, its public IP, and its
  subnet associations
- the current `dev.tfvars` attaches NAT Gateway to `AzureFirewallSubnet`
- this is primarily a scale and egress-control enhancement, not a replacement
  for firewall routing or firewall rules

## How To Customize Firewall Policy Rules

Firewall Policy rules are configured separately from subnet NSGs.

In this stack:

- subnet NSGs are defined through subnet `nsg_rules`
- firewall policy rules are defined through `firewall_network_rule_collections`

The connectivity stack now exposes `firewall_network_rule_collections` at the
stack root, so the normal override point is:

- `terraform/stacks/dev/platform-v2/connectivity/dev.tfvars`

The current `dev` sample enables one collection:

- `spoke-to-internet`
- action `Allow`
- one rule named `allow-web`
- source CIDRs `10.0.0.0/16` and `10.20.0.0/16`
- destination ports `80` and `443`
- destination addresses `*`

When you add more workload spokes, update the source CIDRs so the firewall rule
collections reflect the address spaces that are actually routed through the
hub.

Those rule collections are now rendered into an Azure Firewall Policy rule
collection group, which is the better enterprise pattern for centralized rule
management.

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

## Additional Customizations To Consider

If you want this stack to evolve from a baseline hub into a fuller enterprise
connectivity hub, these are the next customizations I would normally document
and prioritize.

### DNS And Name Resolution

- add Azure DNS Private Resolver in the `dns-inbound` and `dns-outbound`
  subnets if on-premises or custom DNS integration is required
- decide whether spokes should keep Azure-provided DNS or use a custom DNS
  server / firewall DNS proxy model
- if you use Azure Firewall application rules or FQDN-based network controls,
  align workload DNS with the firewall DNS path

### Secured Egress And Transit

- add route tables to workload and shared-service subnets so traffic actually
  traverses the firewall
- consider moving from inline firewall rule collections to Azure Firewall Policy
- and rule collection groups when the rulebase grows further
- decide whether forced tunneling or direct internet egress is required
- consider multiple firewall public IPs or NAT Gateway integration for large
  SNAT demand

### Shared Connectivity Services

- add Azure Bastion if secure admin access to private VMs is needed
- add VPN gateway or ExpressRoute gateway if hybrid connectivity is needed
- add gateway transit and routing standards for spokes that must use the hub

### Resiliency And Scale

- add Azure DDoS Network Protection when public IP-based edge resources are in
  use
- consider one hub per region for stronger blast-radius isolation and
  resiliency
- consider a per-region connectivity subscription model if scale or quota
  pressures grow

### Governance And Automation

- centralize private endpoint DNS integration through policy if many workload
  teams will deploy private endpoints
- expose subnet CIDR, NSG, and route-table inputs at the stack root rather than
  editing child module defaults directly
- document which customizations belong in connectivity versus workload stacks so
  ownership stays clear

## How The Pieces Work Together To Form The Hub

The hub is formed in this order:

1. the stack creates the connectivity resource group
2. the stack calls `modules/vnet-hub`
3. `modules/vnet-hub` selects the default 6-subnet hub layout
4. `modules/vnet-hub` calls `modules/network`
5. `modules/network` creates the VNet and all six subnets
6. `modules/network` creates NSGs only if subnet rules were supplied
7. `modules/vnet-hub` optionally adds Azure Firewall, Azure Firewall Policy,
   and policy-based network rule collections on the reserved firewall subnet
8. `modules/vnet-hub` can optionally add NAT Gateway on selected hub subnets
9. `modules/vnet-hub` can optionally add Azure Bastion on
   `AzureBastionSubnet`
10. the stack calls `modules/private-dns`
11. `modules/private-dns` creates the shared Private DNS zones and links the
   hub VNet to them

That combination gives you:

- a hub VNet
- a hub subnet plan for shared services and future expansion
- optional hub security controls such as subnet NSGs, firewall, NAT-backed
  egress scaling, and Bastion-based admin access
- a centralized Private DNS layer for Private Endpoint resolution

## Outputs Other Stacks Use

This stack publishes the shared network facts that other stacks consume:

- `hub_vnet_id`
- `hub_vnet_name`
- `hub_subnet_ids`
- `firewall_private_ip`
- `firewall_policy_id`
- `firewall_public_ip`
- `nat_gateway_id`
- `nat_gateway_public_ip`
- `bastion_id`
- `bastion_public_ip`
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
- if you enable the firewall, remember that route tables are still required if
  you want spokes to actually send traffic through it
