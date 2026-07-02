# Net-New Hub/Spoke Landing Zone

This pattern is the first implementation path for Compeer's new Azure IaC foundation. It uses HCP Terraform workspaces, the Terraform 2.0 module catalog, policy-as-code, and explicit platform outputs to deploy a hub/spoke landing zone without inheriting legacy drift.

## Workspace Order

| Order | Root | Purpose | Produces |
| --- | --- | --- | --- |
| 1 | `global-governance` | Management group, subscription placement, Azure Policy, RBAC, budget, and broad guardrail scaffold | Management group IDs, policy assignment IDs, role assignment IDs, budget IDs |
| 2 | `platform-management` | Shared observability foundation | Log Analytics workspace ID, action group ID |
| 3 | `platform-connectivity` | Hub/spoke network, subnets, NSGs, route tables, Private DNS | VNet IDs, subnet ID maps, private DNS zone IDs |
| 4 | `platform-hybrid-connectivity` | Optional ExpressRoute circuit, gateway, and on-prem connection path | ExpressRoute circuit, gateway, and connection IDs |
| 5 | `platform-identity` | Platform identity and vault foundation | Identity principal IDs, Key Vault URI/ID |
| 6 | `workload-spoke` | Pilot workload network spoke composition | Spoke VNet ID/name, spoke subnet ID map |
| 7 | `network-peering` | Cross-subscription hub/spoke attachment | Peering IDs, spoke Private DNS link IDs |
| 8 | Consumer workload roots, such as `consumer-repos/online-banking/clientsync/environments/np1` | Application resources in the workload spoke | App resource IDs and endpoint evidence |

Use separate HCP workspaces and state files for these roots in enterprise use. Governance, management, connectivity, hybrid connectivity, identity, and workload spokes have different owners, permissions, blast radius, and change windows. Combining them is acceptable only for short-lived local proof-of-concept work.

`platform-hybrid-connectivity` is intentionally optional. Compeer's heavy on-premises presence means ExpressRoute is expected for a production landing zone, but the circuit, peering location, bandwidth, BGP, and route-advertisement design must come from the approved network/carrier design before deployment.

## Promotion Approach

Start with non-production. Prove the pattern with one pilot workload, then promote by environment only after policy, drift, diagnostics, access, and rollback expectations are validated.

## Shared Output Contract

Platform workspaces publish explicit outputs for workload workspaces to consume. Workload modules receive exact IDs rather than inferring placement internally.

Required shared outputs include:

- `log_analytics_workspace_id`
- `action_group_id`
- `hub_virtual_network_id`, `hub_virtual_network_name`, and `hub_resource_group_name`
- `spoke_virtual_network_id`, `spoke_virtual_network_name`, `spoke_resource_group_name`, and `subnet_ids`, keyed by purpose such as `app_integration`, `private_endpoints`, `apim`
- `private_dns_zone_ids`, `private_dns_zone_names`, and `private_dns_zone_resource_group_names`, keyed by service such as `app_service`, `key_vault`, `storage_blob`
- platform identity or Key Vault IDs where workloads are approved to consume them

## Cost-Safe Test Posture

The checked-in non-production tfvars are shaped for a short smoke test:

- Defender for Cloud Standard plans are disabled in `platform-management/terraform.tfvars`.
- Azure Firewall, ExpressRoute, VPN, DNS Resolver, DDoS Network Protection, and Recovery Services Vaults are represented by modules or optional roots, but are not enabled by default.
- Private DNS zones, VNets, NSGs, route tables, identities, policies, budgets, and locks are generally low-cost or no-cost for a short test.

Before enterprise or production testing, review and intentionally enable the paid controls:

- Defender for Cloud Standard plans in `platform-management`.
- Azure Firewall and Firewall Policy in `platform-connectivity`.
- DDoS Network Protection for production internet-facing VNets.
- ExpressRoute circuit, gateway, and connections in `platform-hybrid-connectivity`.
- Recovery Services Vault and backup policies in the management or workload recovery design.

## Enterprise Baseline Backlog

The current baseline is enough to prove HCP workspaces, state separation, Azure Policy, OPA policy checks, hub/spoke networking, private DNS, central management, and identity/vault scaffolding. It is not yet a complete enterprise landing zone.

Recommended additions before production promotion:

- Azure Firewall or approved NVA, plus firewall policy, route tables, diagnostics, and change workflow.
- ExpressRoute, BGP/routing standards, on-prem DNS integration, and hybrid failover design.
- Azure DNS Private Resolver inbound/outbound endpoints and forwarding rulesets.
- DDoS Network Protection for production public ingress surfaces.
- Sentinel/SIEM onboarding and data-collection rules aligned to security operations.
- Backup/recovery vaults, policies, and restore testing for stateful workloads.
- Subscription vending, IPAM, naming reservation, and workload onboarding automation.
- PIM/RBAC group model, break-glass procedures, and access reviews.
- Approved ingress patterns such as Application Gateway/WAF, Front Door, or Load Balancer where workloads require them.

## Enforcement Approach

OPA begins in advisory mode through HCP plan checks. Azure Policy runtime guardrails are deployed from `global-governance` at management-group or subscription scope, starting with Audit/advisory impact review and then moving selected net-new controls to Deny after the pilot has passed. Existing projects remain outside the blocking policy set until they are remediated.

The current OPA deployment model creates one individual OPA policy and attaches it to one OPA policy set. The policy bundles the Rego and required JSON data because some HCP test/free organizations do not support uploaded/versioned policy sets. The Azure DevOps OPA pipeline validates Rego, bundles the data, runs a local `opa check`/`opa eval`, then plans/applies the HCP policy resources on protected branches.
