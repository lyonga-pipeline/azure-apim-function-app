# Dev Workload V2 FinServ API

## Purpose

This stack is the reference workload landing zone for the `finserv-api`
application.

It shows how a workload should consume shared platform services while still
owning its own spoke network, workload-local resources, private endpoints, and
application identities.

For the broader design rationale, see `terraform/README-v2.md`.

## What This Stack Owns

- the workload resource group
- the workload spoke VNet and subnets
- workload-local NSGs
- the workload-to-hub peering
- the spoke links to shared Private DNS zones
- workload-local services such as storage and Key Vault
- private endpoints for workload services
- workload-local RBAC and diagnostics wiring

## What This Stack Reads From

- `platform-v2/connectivity` remote state
  - supplies the hub VNet and shared Private DNS zones
- `platform-v2/management` remote state
  - supplies the shared Log Analytics workspace
- optional `platform-v2/identity` remote state
  - supplies shared identity and CMK outputs when enabled
- optional `global/subscriptions` remote state
  - validates the workload subscription

## Module Composition

The workload root is broader than the connectivity root, but the spoke network
path is still clean and explicit.

1. `module "resource_group"`
   Creates the workload resource group.
2. `locals.spoke_subnets`
   Builds the full spoke subnet map in the workload root, including CIDRs,
   NSG rules, subnet delegation, and the optional APIM subnet.
3. `module "spoke_network"`
   Calls `modules/vnet-spoke` with the workload-defined subnet map.
4. `modules/vnet-spoke -> module "network"`
   Calls the generic `modules/network` module to create the VNet, subnets,
   NSGs, NSG rules, and subnet associations.
5. `resource "azurerm_private_dns_zone_virtual_network_link" "spoke_links"`
   Links the spoke VNet to every shared Private DNS zone from the connectivity
   stack.
6. `module "hub_to_spoke_peering"`
   Creates both directions of VNet peering between the workload spoke and the
   platform hub.
7. private endpoint modules
   Place private endpoints into the spoke `private-endpoints` subnet and attach
   them to the shared Private DNS zones from connectivity.

That means the spoke is formed by combining:

- a workload resource group
- a workload-owned spoke VNet
- subnet-level NSGs and delegation
- hub peering
- shared DNS integration
- private endpoints for workload services

## Current Dev Deployment Shape

The checked-in `dev.tfvars` currently deploys:

- resource group `rg-dev-loans-api`
- spoke VNet `vnet-dev-loans-api`
- spoke VNet CIDR `10.20.0.0/16`
- Azure region `eastus2`
- demo Windows VM enabled
- Function App disabled
- Service Bus disabled
- App Configuration disabled
- APIM disabled
- SQL disabled
- ACR disabled

So the current sample still builds the full spoke foundation, but only a subset
of the optional workload services are enabled.

## How The Spoke VNet Is Built

This stack does **not** rely on the default subnet layout inside
`modules/vnet-spoke`.

Instead, the workload root builds the subnet map itself in `locals.tf` and
passes that explicit map into `module "spoke_network"`. That is important,
because it means:

- subnet CIDRs are controlled by stack variables in this root
- NSG rules are controlled by stack locals in this root
- the optional APIM subnet is added by the workload root, not by `vnet-spoke`
- the App Service delegation is added by the workload root, not by `vnet-spoke`

`modules/vnet-spoke` then passes that full subnet map into the generic
`modules/network` module, which creates the actual Azure VNet, subnets, NSGs,
NSG rules, and subnet associations.

## Spoke Subnet Layout

With the current root logic, the workload creates **4 subnets by default** and
**5 subnets when APIM is enabled**.

| Subnet | Current CIDR | NSG | Purpose |
| --- | --- | --- | --- |
| `app` | `10.20.1.0/24` | Yes | app-tier subnet; current demo VM defaults here |
| `integration` | `10.20.2.0/24` | Yes | Function App VNet integration subnet; delegated to `Microsoft.Web/serverFarms` |
| `data` | `10.20.3.0/24` | Yes | workload data-tier subnet |
| `private-endpoints` | `10.20.10.0/24` | No | private endpoints for storage, Key Vault, SQL, Function App, and other services |
| `apim` | `10.20.20.0/24` | No | optional subnet created only when `enable_apim = true` |

Important detail:

- the VNet CIDR comes from `spoke_address_space`
- the subnet CIDRs come from stack variables such as `app_subnet_cidr` and
  `private_endpoints_subnet_cidr`
- because this stack passes a non-empty `subnets` map into `vnet-spoke`, the
  fallback default subnet map inside `modules/vnet-spoke` is not used here

## How CIDRs Are Set

The address ranges are set in two layers:

1. VNet CIDR
   `spoke_address_space` is passed from this stack into `modules/vnet-spoke`,
   then into `modules/network`, and becomes the VNet `address_space`.
2. Subnet CIDRs
   the workload root uses these variables to build `locals.spoke_subnets`:
   `app_subnet_cidr`, `integration_subnet_cidr`, `data_subnet_cidr`,
   `private_endpoints_subnet_cidr`, and optionally `apim_subnet_cidr`

In the current `dev` example:

- VNet CIDR: `10.20.0.0/16`
- app subnet: `10.20.1.0/24`
- integration subnet: `10.20.2.0/24`
- data subnet: `10.20.3.0/24`
- private endpoints subnet: `10.20.10.0/24`
- APIM subnet: `10.20.20.0/24` when APIM is enabled

## NSG Behavior

NSGs are created by the generic `modules/network` module, but the rules come
from `locals.tf` in this workload root.

Current subnet security behavior:

- `app` gets an NSG with 2 rules
- `integration` gets an NSG with 5 rules
- `data` gets an NSG with 2 rules
- `private-endpoints` gets no NSG
- `apim` gets no NSG in the current implementation

That means the current checked-in `dev` sample creates:

- **3 NSGs**
- **3 NSG associations**

### Current App Subnet Rules

- allow VNet inbound
- deny Internet inbound

### Current Integration Subnet Rules

- allow outbound `443` to `AzureMonitor`
- allow outbound `443` to `Storage`
- allow outbound `443` to `AzureKeyVault`
- allow outbound `1433` to `Sql`
- deny Internet outbound

### Current Data Subnet Rules

- allow VNet inbound
- deny Internet inbound

## Other Subnet-Level Features Supported By The Child Modules

The generic `modules/network` module can also apply optional subnet settings
when they are included in the subnet map:

- service endpoints
- route tables
- NAT gateways
- additional subnet delegations

This workload stack does not currently pass route tables, NAT gateways, or
service endpoints for the spoke subnets. The one active delegation is the App
Service delegation on the `integration` subnet.

## Delegation And Private Endpoint Behavior

Two subnet behaviors are especially important in this stack.

### Integration Subnet

The `integration` subnet is delegated to `Microsoft.Web/serverFarms`.

That is what makes it suitable for App Service or Function App VNet
integration. When the Function App is enabled, the stack places that
integration on this subnet.

### Private Endpoints Subnet

The `private-endpoints` subnet is created with private endpoint network
policies disabled.

That is intentional. It makes the subnet suitable for Azure Private Endpoints.

## Which Workload Components Use Which Subnets

The current stack uses the spoke subnets like this:

- `app`
  - the optional demo Windows VM defaults to this subnet
- `integration`
  - the Function App uses this subnet for VNet integration when enabled
- `data`
  - reserved for workload data-tier resources or future internal compute
- `private-endpoints`
  - storage private endpoints
  - Key Vault private endpoint
  - optional App Configuration private endpoint
  - optional Service Bus private endpoint
  - optional SQL private endpoint
  - optional Function App private endpoint
- `apim`
  - API Management uses this subnet when enabled in internal mode

## Current Dev Network Outcome

With the current `dev.tfvars`, the effective spoke network shape is:

- 1 workload resource group
- 1 spoke VNet
- 4 subnets
- 3 NSGs
- 3 NSG associations
- 1 bidirectional hub peering pair
- 9 Private DNS zone links to the shared hub-managed zones
- 5 private endpoints in the `private-endpoints` subnet

Those 5 current private endpoints are:

- storage blob
- storage file
- storage queue
- storage table
- Key Vault

Because Function App, Service Bus, App Configuration, SQL, and APIM are
disabled in the current `dev` sample, their network integrations are reserved
but not yet deployed.

## How Hub Peering And Shared DNS Work

This stack does not create its own private DNS zones and does not create its
own hub.

Instead it consumes the connectivity stack outputs and integrates the spoke
into the shared platform network.

It does that in two ways:

1. hub peering
   `module "hub_to_spoke_peering"` creates both directions of peering between
   the shared hub VNet and the workload spoke VNet.
2. Private DNS links
   `azurerm_private_dns_zone_virtual_network_link.spoke_links` links the spoke
   VNet to every Private DNS zone published by the connectivity stack.

That is what lets workload private endpoints resolve correctly through the
shared platform DNS plane.

## How The Pieces Work Together To Form The Spoke

The spoke is formed in this order:

1. the stack creates the workload resource group
2. the stack builds the subnet map in `locals.spoke_subnets`
3. the stack calls `modules/vnet-spoke`
4. `modules/vnet-spoke` passes the workload-defined subnet map into
   `modules/network`
5. `modules/network` creates the spoke VNet, subnets, NSGs, rules, and
   associations
6. the stack creates bidirectional peering between the spoke and the shared hub
7. the stack links the spoke VNet to every shared Private DNS zone from
   connectivity
8. the workload services create private endpoints into the
   `private-endpoints` subnet as needed

That combination gives you:

- a workload-owned spoke VNet
- subnet-level isolation through NSGs
- private-only service connectivity
- shared hub reachability
- shared Private DNS resolution

## Outputs Other Consumers Use

This stack publishes several outputs that operators and deployment pipelines
consume:

- `resource_group_name`
- `subscription_id`
- `spoke_vnet_id`
- `key_vault_uri`
- `storage_account_name`
- optional service outputs such as `function_app_name` and
  `api_management_name`

## Practical Notes

- this is the correct root for workload-local spoke networking
- the spoke subnet map is intentionally workload-defined, not platform-defined
- if you add a new workload service that needs private access, it should
  normally consume the existing `private-endpoints` subnet
- if you add a new runtime that needs delegated subnet integration, the
  delegation should be made explicit in this root
- if you expect APIM subnet isolation, you should add explicit NSG rules for
  the `apim` subnet because the current implementation creates that subnet
  without NSG rules
