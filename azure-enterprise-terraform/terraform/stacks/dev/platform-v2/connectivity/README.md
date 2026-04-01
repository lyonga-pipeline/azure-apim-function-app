# Dev Platform V2 Connectivity

## Purpose

This stack is the shared network foundation for the `dev` platform plane.

It owns the hub-side networking and the shared Private DNS zones that other
platform and workload stacks consume.

For the broader design rationale, see `terraform/README-v2.md`.

## Why This Stack Exists

- Workloads should not each create their own hub network.
- Private endpoint DNS works best when it is managed centrally.
- Shared network services need a separate lifecycle from application resources.

## What This Stack Owns

- the connectivity resource group
- the hub VNet
- the hub subnets
- the shared Private DNS zones
- the hub VNet links to those Private DNS zones

## What It Reads From

- direct environment inputs such as names, address spaces, and location
- optional `global/subscriptions` remote state for subscription validation

This stack does not depend on identity, management, or workload state.

## Subscription Catalog Mapping

This sample stack should use the `connectivity` entry in
`global/subscriptions`.

That means:

- `subscription_catalog_entry_key = "connectivity"`
- `subscription_id` should eventually match the real connectivity subscription
  ID recorded in the central catalog

Why this matters:

- the connectivity stack is a shared platform service
- it should validate against the connectivity platform subscription, not a
  generic shared platform placeholder
- this keeps the sample aligned with the stronger enterprise pattern of one
  subscription per major platform function

## Main Inputs

- `subscription_id`
  - Makes the target subscription explicit and supports catalog validation.
- `location`
  - Defines where the platform network resources will live.
- naming inputs
  - Keep the hub VNet, resource group, and DNS naming consistent.
- hub address-space and subnet inputs
  - Define the network layout that downstream spokes will connect to.
- private DNS zone inputs
  - Define which centrally managed private service zones this platform should
    publish.

## What This Stack Does

- creates the connectivity resource group
- builds standard tags
- creates the hub VNet through the shared `vnet-hub` module
- creates the shared Private DNS zones
- links the hub VNet to those zones
- optionally validates that its subscription matches the central subscription
  catalog

## What Other Stacks Use From It

- `platform-v2/identity`
  - Uses the hub VNet and DNS information for peering and DNS linking.
- `workload-v2/*`
  - Use the hub VNet, DNS zones, and hub-side network metadata to attach their
    spokes and private endpoints.

This stack is one of the main shared-service providers in the platform layer.

## Main Building Blocks

- `module "tags"`
  - Builds the standard platform tag set.
- `module "resource_group"`
  - Creates the connectivity resource group.
- `module "hub_network"`
  - Creates the hub VNet and hub subnets.
- `module "private_dns"`
  - Creates the shared private DNS zones and hub links.

## Code Map

- `data.tf`
  - Optional subscription catalog validation.
- `main.tf`
  - Creates the resource group, hub network, and shared DNS.
- `outputs.tf`
  - Publishes hub and DNS outputs for downstream stacks.
- `dev.tfvars`
  - Supplies environment-specific naming and address space values.

## How To Extend It

- Add Bastion, Firewall, DNS resolver, or routing assets here if they are
  shared platform services.
- Keep spoke-local networking out of this root.
- Publish any new shared network fact as an output before expecting another
  stack to consume it.

## Best-Practice Notes

This is the right place for shared hub networking and shared Private DNS.

Keeping connectivity centralized makes it much easier for new engineers to see:

- where shared routing lives
- where private endpoint DNS is managed
- which outputs workload stacks should depend on

### Should The Hub VNet Be Global Or Per Environment?

This pattern treats the hub as an environment platform asset, not as one
single global hub for the entire company.

That is a good enterprise pattern.

Why this is usually the better default:

- prod and nonprod often need different routing, inspection, and change
  controls
- different environments usually have different blast-radius requirements
- teams can evolve one environment platform without changing every other
  environment at the same time
- hub resources are regional by nature, so organizations often end up with
  multiple hubs anyway

### Practical Recommendation

- use a shared hub for each environment platform boundary
- let workload spokes attach to the correct environment hub
- split hubs further by region or security boundary when the organization grows
- only use one very high-level shared global network plane when the operating
  model truly requires shared transit or shared corporate edge services

In other words:

- one global hub for everything is not required
- one shared hub per environment is a strong default
- multiple hubs by region or security boundary is a common enterprise evolution

### On-Prem Connectivity Patterns

When a company needs VPN or ExpressRoute connectivity from on-premises into
Azure, the important design choice is the transit model.

The company does not automatically need a different physical VPN or
ExpressRoute design for every landing zone. The right answer depends on how
the hubs are organized.

#### Pattern 1. One Shared Connectivity Hub

- on-prem connects once to a shared Azure hub
- prod and nonprod spokes both use that hub gateway through peering and gateway
  transit
- this is the simplest model

Why teams choose it:

- less Azure gateway sprawl
- simpler to understand
- lower operational overhead

Tradeoff:

- prod and nonprod share more network blast radius

#### Pattern 2. Separate Hubs For Prod And Nonprod

- prod has its own hub and gateway path
- nonprod has its own hub and gateway path
- spokes attach only to the correct environment hub

Why teams choose it:

- stronger isolation
- easier separation of routing, inspection, and change control
- better fit for regulated environments

Tradeoff:

- more Azure gateway cost
- more network operations complexity

#### Pattern 3. Multiple Hubs With Shared Transit

- each environment or region can still have its own hub
- on-prem connectivity is handled through a higher shared transit design
- in Azure, this is commonly done with Virtual WAN

Why teams choose it:

- supports large multi-region estates
- avoids treating each environment as a totally separate one-off network edge
- keeps hub separation while still providing enterprise transit

Tradeoff:

- more architecture and operations complexity than a single shared hub

### Practical Recommendation For Financial Companies

- small to mid-size estate:
  - one shared connectivity hub can be acceptable if the security model allows
    it
- regulated prod and nonprod separation:
  - separate prod and nonprod hubs is usually the safer choice
- large multi-region estate:
  - multiple hubs with a shared transit model is often the best answer

So if the company does not want "a different VPN per environment", the usual
enterprise answer is not to force every environment into one hub. The better
answer is often:

- one shared connectivity hub for simpler estates, or
- multiple hubs with centralized transit for larger estates
